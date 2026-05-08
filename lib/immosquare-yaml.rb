require          "psych"
require          "fileutils"
require          "immosquare-extensions"
require_relative "immosquare-yaml/shared_methods"
require_relative "immosquare-yaml/flatten"

##============================================================##
## ImmosquareYaml — post-processeur Psych dédié aux fichiers
## de traduction (locales Rails).
##
## Trois responsabilités :
##   - parse(file)  : YAML → Hash, en s'appuyant sur l'AST Psych
##   - dump(hash)   : Hash → YAML formaté (quotes minimales,
##                    blocs littéraux, emojis décodés)
##   - clean(file)  : parse + tri par clé + dump → écrit
##
## La gem résout cinq problèmes que Psych seul ne traite pas :
##   1. Norway problem (yes/no/on/off lus comme String)
##   2. Tri déterministe par clé
##   3. Préservation des blocs littéraux (|, |-)
##   4. Quotes minimales pour la lisibilité
##   5. Décodage des escapes \U0001F600 → emoji
##============================================================##
module ImmosquareYaml
  extend SharedMethods

  class << self

    ##============================================================##
    ## clean(file_path, sort: true, output: file_path)
    ## Charge le fichier, le re-écrit propre et trié.
    ## Retourne true / false selon le succès.
    ##============================================================##
    def clean(file_path, **options)
      options = {
        :sort   => true,
        :output => file_path
      }.merge(options)

      begin
        raise("File not found") if !File.exist?(file_path)

        parsed_yml = parse(file_path, :sort => options[:sort])
        return false if parsed_yml == false

        output = dump(parsed_yml)
        FileUtils.mkdir_p(File.dirname(options[:output]))
        File.write(options[:output], output)
        true
      rescue StandardError => e
        puts(e.message)
        puts(e.backtrace)
        false
      end
    end

    ##============================================================##
    ## parse(file_path, sort: true)
    ## Lit un fichier YAML et retourne un Hash Ruby.
    ## Hash trié par clé par défaut.
    ##
    ## Implémentation : on parcourt l'AST Psych plutôt que d'appeler
    ## Psych.load. Cela permet de :
    ##   - distinguer un scalaire plain "yes" d'un bool true
    ##   - garder les valeurs problématiques (Norway) en String
    ##   - décoder nous-mêmes les escapes \U... pour les blocs
    ##     littéraux qui ne sont pas désescapés par Psych
    ##============================================================##
    def parse(file_path, **options)
      options = {:sort => true}.merge(options)

      begin
        raise("File not found") if !File.exist?(file_path)

        ##============================================================##
        ## Psych.parse_file retourne un Document. Si le fichier est
        ## vide ou ne contient que des commentaires, root est nil.
        ##============================================================##
        doc = Psych.parse_file(file_path)
        return {} if !doc || doc.root.nil?

        result = node_to_value(doc.root, {})

        ##============================================================##
        ## On accepte tous les types racine (Hash, Array, scalaire),
        ## mais on ne trie que si la racine est un Hash.
        ##============================================================##
        result = result.sort_by_key if options[:sort] && result.is_a?(Hash)
        result
      rescue StandardError => e
        puts(e.message)
        puts(e.backtrace)
        false
      end
    end

    ##============================================================##
    ## dump(hash) → String YAML
    ## Sérialise un Hash en YAML avec nos règles de formatage :
    ##   - clés "yes/no/on/..." re-quotées
    ##   - valeurs plain quand c'est sûr, sinon doublequotées
    ##   - chaînes multi-lignes en bloc littéral | ou |-
    ##   - arrays imbriqués délégués à Psych.dump puis indentés
    ##============================================================##
    def dump(hash)
      render_hash(hash, [], 0)
    end


    private


    ##============================================================##
    ## Rendu récursif d'un Hash. Les paramètres lines et indent
    ## sont des accumulateurs internes — exposés dans la signature
    ## privée uniquement.
    ##============================================================##
    def render_hash(hash, lines, indent)
      hash.each do |key, value|
        line = "#{SPACE * indent}#{clean_key(key)}:"

        case value
        when nil
          lines << "#{line} null"
        when String
          if value.include?(NEWLINE) || value.include?('\n')
            ##============================================================##
            ## Bloc littéral. On ajoute "-" si la valeur ne se termine
            ## pas par un newline (chomp). Indent indicator si la valeur
            ## a des leading spaces sur ses lignes.
            ##============================================================##
            line        += "#{SPACE}|"
            indent_level = value[/\A */].size
            line        += (indent_level + INDENT_SIZE).to_s if indent_level > 0
            line        += "-" if !value.end_with?(NEWLINE)
            lines << line

            ##============================================================##
            ## Décode les escapes \U0001F600 dans les blocs littéraux
            ## (Psych ne les désescape pas pour LITERAL/FOLDED).
            ##============================================================##
            value = decode_unicode_escapes(value)

            value.split(/\\n|\n/).each do |subline|
              lines << "#{SPACE * (indent + INDENT_SIZE)}#{subline}"
            end
          else
            line += "#{SPACE}#{format_scalar_value(value)}"
            lines << line
          end
        when Hash
          lines << line
          render_hash(value, lines, indent + INDENT_SIZE)
        when Array
          formated_value = Psych.dump(value)
          if formated_value == "--- []\n"
            lines << "#{line} []"
          else
            formated_value = formated_value.gsub("---#{NEWLINE}", NOTHING)
              .split(NEWLINE).map {|l| "#{SPACE * (INDENT_SIZE + indent)}#{l}" }
              .join(NEWLINE)
            lines << line
            lines << formated_value
          end
        else
          ##============================================================##
          ## Numbers, booleans, dates : laissés tels quels.
          ##============================================================##
          line += "#{SPACE}#{value}"
          lines << line
        end
      end

      lines += [NOTHING]
      lines = lines.map {|l| l.strip.empty? ? NOTHING : l }
      lines.join("\n")
    end

    ##============================================================##
    ## Walker AST : transforme un Psych::Nodes::* en valeur Ruby.
    ## Le hash anchors mémorise les ancres rencontrées pour
    ## résoudre les aliases.
    ##============================================================##
    def node_to_value(node, anchors)
      case node
      when Psych::Nodes::Scalar
        value = scalar_to_ruby(node)
        anchors[node.anchor] = value if node.anchor
        value
      when Psych::Nodes::Mapping
        h = {}
        node.children.each_slice(2) do |key_node, val_node|
          ##============================================================##
          ## Toujours convertir les clés en String. Cela évite les
          ## hashs aux types mixtes (Integer/String) qui cassent le tri
          ## et déstabilisent les fichiers de traduction.
          ##============================================================##
          key    = node_to_value(key_node, anchors).to_s
          h[key] = node_to_value(val_node, anchors)
        end
        anchors[node.anchor] = h if node.anchor
        h
      when Psych::Nodes::Sequence
        arr = node.children.map {|c| node_to_value(c, anchors) }
        anchors[node.anchor] = arr if node.anchor
        arr
      when Psych::Nodes::Alias
        raise("Unknown YAML alias: *#{node.anchor}") if !anchors.key?(node.anchor)

        anchors[node.anchor]
      else
        raise("Unsupported YAML node type: #{node.class}")
      end
    end

    ##============================================================##
    ## Convertit un Psych::Nodes::Scalar en valeur Ruby.
    ## Règles :
    ##   - quoted (single/double) → toujours String
    ##   - plain vide ou null/~ → nil
    ##   - plain "yes/no/on/off/true/false" → String (Norway problem)
    ##   - plain entier → Integer
    ##   - plain flottant → Float
    ##   - sinon → String
    ##   - LITERAL/FOLDED : String, mais on décode \U... à l'usage
    ##     dans le dump (pas ici, pour ne pas perdre l'info brute)
    ##============================================================##
    def scalar_to_ruby(node)
      raw   = node.value
      style = node.style

      return raw if [Psych::Nodes::Scalar::SINGLE_QUOTED, Psych::Nodes::Scalar::DOUBLE_QUOTED].include?(style)
      return raw if [Psych::Nodes::Scalar::LITERAL, Psych::Nodes::Scalar::FOLDED].include?(style)

      ##============================================================##
      ## Style PLAIN : on type prudemment.
      ##============================================================##
      return nil if raw == NOTHING || ["~", "null", "Null", "NULL"].include?(raw)
      return raw if RESERVED_KEYS.include?(raw)
      return raw.to_i if raw.match?(/\A-?\d+\z/)
      return raw.to_f if raw.match?(/\A-?\d+\.\d+\z/)

      raw
    end

    ##============================================================##
    ## Décode les séquences \U0001F600 en emoji UTF-8.
    ## Appelé sur les valeurs string au moment du dump (pas au
    ## parse, pour préserver l'idempotence si l'utilisateur a vraiment
    ## la séquence littérale dans son YAML).
    ##============================================================##
    def decode_unicode_escapes(value)
      value.gsub(/\\U([0-9A-Fa-f]{8})/) { [::Regexp.last_match(1).to_i(16)].pack("U*") }
    end

    ##============================================================##
    ## clean_key : prépare une clé pour le dump.
    ## - retire les quotes englobantes éventuelles
    ## - re-quote si la clé est un mot réservé YAML 1.1 ou un entier
    ##============================================================##
    def clean_key(key)
      key    = strip_wrapping_quotes(key.to_s)
      is_int = key.match?(/\A[-+]?\d+\z/)
      key    = "\"#{key}\"" if RESERVED_KEYS.include?(key) || is_int
      key
    end

    ##============================================================##
    ## format_scalar_value : prépare une valeur String pour le dump.
    ## Décode les escapes Unicode et décide si on doit quoter.
    ##
    ## On quote si la valeur contient des caractères qui auraient
    ## un sens YAML particulier en plain (": ", " #", début par un
    ## caractère spécial, fin par ":", mot réservé, espace en bord).
    ##============================================================##
    def format_scalar_value(value)
      value = value.to_s
      value = decode_unicode_escapes(value)
      value = value.gsub(WEIRD_QUOTES_REGEX, SIMPLE_QUOTE)

      ##============================================================##
      ## On enlève les guillemets parasites éventuels (cas de fichiers
      ## historiques produits par l'ancienne version).
      ##============================================================##
      value = strip_wrapping_quotes(value)

      ##============================================================##
      ## Note : un " au milieu d'une string plain est légal en YAML.
      ## On ne quote que si le " est en début (déjà couvert par
      ## start_with?(*YML_SPECIAL_CHARS)). Quoter dès qu'un " apparaît
      ## n'importe où dans la valeur produirait des diffs inutiles.
      ##============================================================##
      need_quotes = value.empty? ||
                    value.include?(": ") ||
                    value.include?(" #") ||
                    value.start_with?(*YML_SPECIAL_CHARS) ||
                    value.end_with?(":") ||
                    RESERVED_KEYS.include?(value) ||
                    value.start_with?(SPACE) ||
                    value.end_with?(SPACE)

      return value if !need_quotes

      ##============================================================##
      ## Choix du style de quoting :
      ##   - double-quoted par défaut (cohérent avec la règle Ruby
      ##     globale "double quotes obligatoires")
      ##   - single-quoted seulement si la valeur contient un " ou
      ##     un \ (qui devraient être échappés en double-quoted),
      ##     sauf si la valeur contient aussi un \t qui ne peut être
      ##     représenté qu'en double-quoted.
      ##============================================================##
      if (value.include?(DOUBLE_QUOTE) || value.include?("\\")) && !value.include?("\t")
        yaml_single_quote(value)
      else
        yaml_double_quote(value)
      end
    end

    ##============================================================##
    ## Échappe une string pour la sérialiser en YAML double-quoted.
    ## On gère \, ", \t et \n. Les newlines réels n'arrivent pas
    ## ici car ils sont rendus en bloc littéral plus haut.
    ##============================================================##
    def yaml_double_quote(value)
      escaped = value.gsub("\\", "\\\\\\\\").gsub("\"", '\\"').gsub("\t", '\\t')
      "\"#{escaped}\""
    end

    ##============================================================##
    ## Échappe une string pour la sérialiser en YAML single-quoted.
    ## En single-quoted, le seul caractère à échapper est l'apostrophe
    ## elle-même, doublée. Ni \, ni " ne sont interprétés.
    ##============================================================##
    def yaml_single_quote(value)
      escaped = value.gsub(SIMPLE_QUOTE, DOUBLE_SIMPLE_QUOTE)
      "#{SIMPLE_QUOTE}#{escaped}#{SIMPLE_QUOTE}"
    end

    ##============================================================##
    ## Retire récursivement les paires de guillemets englobants.
    ## Sert pour les fichiers historiques produits par v0.1.28
    ## qui pouvaient contenir des valeurs avec quotes incluses.
    ##============================================================##
    def strip_wrapping_quotes(value)
      value = value[1..-2] while (value.start_with?(DOUBLE_QUOTE) && value.end_with?(DOUBLE_QUOTE)) || (value.start_with?(SIMPLE_QUOTE) && value.end_with?(SIMPLE_QUOTE))
      value
    end

  end
end
