module ImmosquareYaml
  class << self

    INDENT_SIZE         = 2
    SPACE               = " ".freeze
    NEWLINE             = "\n".freeze
    SIMPLE_QUOTE        = "'".freeze
    DOUBLE_QUOTE        = '"'.freeze
    DOUBLE_SIMPLE_QUOTE = "''".freeze
    WEIRD_QUOTES_REGEX  = /‘|’|“|”|‛|‚|„|‟|#{Regexp.quote(DOUBLE_SIMPLE_QUOTE)}/.freeze
    YML_SPECIAL_CHARS   = ["-", "`", "{", "}", "|", "[", "]", ">", ":", "\"", "'", "*", "=", "%", ",", "!", "?", "&", "#", "@"].freeze
    RESERVED_KEYS       = [
      "yes", "no", "on", "off", "true", "false",
      "Yes", "No", "On", "Off", "True", "False",
      "YES", "NO", "ON", "OFF", "TRUE", "FALSE"
    ].freeze

    ##============================================================##
    ## Pour faire un clean sur un fichier yml en traitant
    ## le fichier ligne par ligne
    ##============================================================##
    def clean(file_path, args = {})      
      begin
        raise("File not found") if !File.exist?(file_path)

        ##============================================================##
        ## On fait un méga clean..
        ## puis on le transforme en hash pour pouvoir le trier
        ## puis on le retransforme en yml 
        ##============================================================##
        clean_yml(file_path)
        yaml_final = parse(file_path)
        yaml_final = sort_by_key(yaml_final, true)
        yaml_final = dump(yaml_final)
        File.write(file_path, yaml_final)  
        true
      rescue StandardError => e
        puts(e.message)
        false
      end
    end

    ##============================================================##
    ## Pour bien parser un fait un clean préalable du fichier 
    ## Puis on le transforme en hash pour pouvoir le trier
    ## partir du principe que le fichier est propre.
    ##============================================================##
    def parse(file_path, args = {})
      begin
        raise("File not found") if !File.exist?(file_path)

        clean_yml(file_path)
        yaml_final = parse_xml(file_path)
        sort_by_key(yaml_final, true)
        
      rescue StandardError => e
        puts(e.message)
        false
      end
    end

    ##============================================================##
    ## On fait un dump pour avoir un fichier yml propre
    ##============================================================##
    def dump(hash, lines = [], indent = 0)
      hash.each do |key, value|
        ##============================================================##
        ## On prépare la clé avec la bonne indentation
        ##============================================================##
        line = "#{SPACE * indent}#{clean_key(key)}:"
        
        ##============================================================##
        ## Si c'est une string, il faut gérer l'affiche
        ## si c'est un hash, on affiche la clé et on relance la méthode
        ## de façon récursive.
        ##============================================================##
        case value
        when nil
          lines << "#{line} null"
        when String
          ##============================================================##
          ## Si il y a des sauts de lignes on gère avec | et |. on 
          ## n'affiche pas directement les \n dans le yml.
          ##============================================================##
          if value.include?(NEWLINE) || value.include?('\n')
            ##============================================================##
            ## On affiche la ligne avec la key l'indentation si nécéssaire
            ## et le  - si nécéssaire (le + on ne l'affiche pas car c'est
            ## le comportement par défaut)
            ##============================================================##
            line        += "#{SPACE}|"
            indent_level = value[/\A */].size
            line        += (indent_level + INDENT_SIZE).to_s if indent_level > 0
            line        += "-" if !value.end_with?(NEWLINE)
            lines << line

            ##============================================================##
            ## On parse sur les 2 types de saut de ligne
            ##============================================================##
            value.split(/\\n|\n/).each do |subline|
              lines << "#{SPACE * (indent + INDENT_SIZE)}#{subline}"
            end
          else
            line += "#{SPACE}#{value}"
            lines << line
          end
        when Hash
          lines << line
          dump(value, lines, indent + INDENT_SIZE)
        end
      end

      ##============================================================##
      ## On fini le fichier avec un retour à la ligne et on supprime
      ## les espaces sur les lignes "vides"
      ##============================================================##
      lines += [""]
      lines = lines.map {|l| l.strip.empty? ? "" : l }
      lines.join("\n")
    end


    private

    ##============================================================##
    ## On veut que le fichier finisse toujours par une ligne vide.
    ## pour que  l'on fasse un dernier passage et faire un clean
    ## de l[-1] si nécéssaire (voir plus bas les block multilines)
    ## On fait cela avec des commandes sytème car Ruby ne propose
    ## pas cela de base.
    ##============================================================##
    def normalize_last_line(file_path)
      lines     = File.read(file_path).lines
      lines[-1] = "#{lines[-1]}#{NEWLINE}" if !lines[-1].end_with?(NEWLINE)
      
      ##============================================================##
      ## Supprimez toutes les lignes vides à la fin du fichier
      ##============================================================##
      lines.pop while lines.last && lines.last.strip.empty?
    
      ##============================================================##
      ## On ajoute notre ligne avec un retour à la ligne
      ##============================================================##
      lines += [NEWLINE]
      
      ##============================================================##
      ## On écrit le fichier
      ##============================================================##
      File.write(file_path, lines.join)

      ##============================================================##
      ## On retourne le nombre de ligne du fichier
      ##============================================================##
      lines.size
    end

    ##============================================================##
    ## On fait un clean du fichier yml en profondeur
    ##============================================================##
    def clean_yml(file_path)
      lines             = []
      inblock_indent    = nil
      weirdblock_indent = nil
      inblock           = false
      weirdblock        = false
      line_index        = 1

      ##============================================================##
      ## On veut savoir le nombre de ligne du fichier pour pouvoir
      ## savoir quand on est sur la dernière ligne
      ## https://gist.github.com/guilhermesimoes/d69e547884e556c3dc95
      ## On commance par normaliser le fichier avec une dernière ligne
      ## vide à chaque fois
      ##============================================================##
      line_count = normalize_last_line(file_path)
      
      
      File.foreach(file_path) do |current_line|
        last_line = line_index == line_count
        ##============================================================##
        ## On clean la ligne... on enlève les multiples espaces
        ## après un charactère non espace.
        ## (?<=\S) : Ceci est une assertion positive lookbehind qui 
        ## vérifie la présence d'un caractère non-espace juste avant
        ## les espaces que nous voulons correspondre. 
        ## Elle ne consomme pas de caractères dans la correspondance, 
        ## elle vérifie juste leur présence.
        ## \s+ : Ceci correspond à un ou plusieurs espaces blancs qui sont 
        ## précédés d'un caractère non-espace
        ##============================================================##
        current_line = current_line.to_s.gsub(/(?<=\S)\s+/, SPACE)

        ##============================================================##
        ## on fait un rstrip sur la ligne pour effacer tous les blancs
        ## potentiels à droite
        ##============================================================##
        current_line = current_line.rstrip
        
        ##============================================================##
        ## Détection si on est dans une ligne blanche (execpté la 
        ## dernière) pour faire un traitement sur la l[-1]. On veut aussi
        ## passer sur la ligne si on est dans un block
        ##============================================================##
        blank_line = current_line.gsub(NEWLINE, "").empty?
        next if !(last_line || inblock || !blank_line)

        ##============================================================##
        ## Détection du niveau d'indentation
        ##============================================================##
        last_inblock                 = inblock
        indent_level                 = current_line[/\A */].size
        need_to_clean_prev_inblock   = inblock    == true && ((!blank_line && indent_level <= inblock_indent) || last_line)
        need_to_clen_prev_weirdblock = weirdblock == true && (indent_level <= weirdblock_indent || last_line)
        
        ##============================================================##
        ## On remet à false le inblock si on était dans un block
        ## et on vient de sortir...On recupère le block en entier et
        ## on le clean
        ##============================================================##
        if need_to_clean_prev_inblock
          inblock = false
          ##============================================================##
          ## On récupère le block en entier en remontant les lignes
          ## jusqu'à avoir une indentation inférieur à celle du block
          ## À ce moment on sait quel type de block c'est.
          ##============================================================##
          i            = -1
          block_indent = lines[i][/\A */].size
          block_lines  = [lines[i].lstrip]
          while lines[i][/\A */].size == lines[i - 1][/\A */].size
            block_lines << lines[i - 1].lstrip
            i -= 1
          end

          ##============================================================##
          ## | => Blocs littéraux : Il conserve les sauts de ligne tels 
          ## qu'ils sont donnés dans le bloc de texte.
          ## Nouvelle ligne finale : Une nouvelle ligne est ajoutée à la
          ## fin du texte.
          ## |- => Blocs littéraux : Il conserve les sauts de ligne tels 
          ## qu'ils sont donnés dans le bloc de texte.
          ## Nouvelle ligne finale : Le saut de ligne final est supprimé, 
          ## contrairement à l'option |
          ## > Blocs pliés : Il remplace chaque nouvelle ligne par un espace, 
          ## transformant le bloc de texte en une seule ligne. 
          ## Cependant, il conserve les nouvelles lignes qui suivent une ligne vide.
          ## Nouvelle ligne finale : Une nouvelle ligne est ajoutée à la fin du texte.
          ## ===
          ## On peut aussi avoir des |4- ou |4+ pour dire avec indentation 4
          ## le plus au moins et pour autre chose..c'est pour la gestion
          ## des \n à la fin
          ##============================================================##
          block_lines  = block_lines.reverse
          block_type   = lines[i - 1].split(": ").last
          indent_suppl = block_type.scan(/\d+/).first.to_i
          indent_suppl = indent_suppl > 0 ? indent_suppl - INDENT_SIZE : 0
          case block_type[0]
          when  ">"
            lines[i - 1] = lines[i - 1].gsub(">", "|")
            lines[i]     = "#{SPACE * (block_indent + indent_suppl)}#{clean_value(block_lines.join(SPACE))}"
            ((i + 1)..-1).to_a.size.times { lines.pop }
          else
            split = clean_value(block_lines.join(NEWLINE), false).split(NEWLINE)
            (i..-1).each do |ii|
              lines[ii] = "#{SPACE * (block_indent + indent_suppl)}#{split.shift}"
            end
          end
        end

        ##============================================================##
        ## On fait pareil avec les "faux multilines"
        ##  key: " 
        ##    line1
        ##    line2
        ##    line3
        ##  key: ' 
        ##    line1
        ##    line2
        ##    line3
        ##============================================================##
        if need_to_clen_prev_weirdblock
          weirdblock  = false 
          key, value  = lines[-1].split(":", 2)
          lines[-1]   = "#{key}: #{clean_value(value)}"
        end

        ##============================================================##
        ## Si on n'est pas dans un block et que la ligne précédente
        ## est une key.
        ## on recupère l'indentation de la ligne précédente
        ## et si elle est suérieur ou égale à l'indentation de la ligne
        ## courante alors la valeur de la ligne précédante est nulle
        ##============================================================##
        if inblock == false && weirdblock == false && lines[-1] && lines[-1].end_with?(":") && last_inblock == false
          prev_indent = lines[-1][/\A */].size
          lines[-1] += " null" if prev_indent >= indent_level
        end

        ##============================================================##
        ## Découpage de la ligne en clé et valeur. Il faut découper
        ## sur ":" et pas sur ": " car on n'a pas d'espace quand c'est
        ## juste une clé.. mais on n'a un retour à la ligne
        ## fr: => ["fr", "\n"]
        ##============================================================##
        split = inblock || weirdblock ? [current_line] : current_line.strip.split(":", 2)
        key   = inblock || weirdblock ? nil : split[0].to_s.strip
        
        ##============================================================##
        ## Si la ligne est en commentaire on la reprend tels que
        ## en enlevant les retours à la ligne
        ##============================================================##
        if current_line.lstrip.start_with?("#")
          lines << current_line.gsub(NEWLINE, "")
        ##============================================================##
        ## Si est en dans un block (multiline > | ou |-), on clean
        ## la ligne car celle ci peut commencer par des espaces tabs etc
        ## et on la met avec l"indenteur du block
        ##============================================================##
        elsif inblock == true
          current_line = current_line.gsub(NEWLINE, "").strip
          lines << "#{SPACE * (inblock_indent + INDENT_SIZE)}#{current_line}"
        ##============================================================##
        ## On rstrip la ligne, si la ligne fini par un charactère 
        ## de multi-lines et que nous avons un key. On commence un block
        ## multi-lines qui commmence par > ou | avec un nombre optionel
        ## et un - ou pas +
        ## Cette regex fonctionne comme suit :
        ##========================================
        ## \S+      : Tous les caractères non-espace au début de la ligne.
        ## :        : Correspond à la chaîne de caractères ": " littéralement (espace inclus).
        ## [>|]     : Correspond à un seul caractère qui est soit ">" soit "|".
        ## (\d*)    : Groupe de capture qui correspond à zéro ou plusieurs chiffres (0-9).
        ## [-+]?    : Correspond à zéro ou un caractère qui est soit "-" soit "+".
        ## $        : Correspond à la fin de la ligne/chaîne.
        ##============================================================##
        elsif current_line.rstrip.match?(/\S+: [>|](\d*)[-+]?$/)
          lines << current_line.gsub(NEWLINE, "")
          inblock_indent = indent_level
          inblock        = true
        ##============================================================##
        ## On est dans le cas de figure d'une de block multiline
        ## mais sans > | ou |- à la fin de la ligne
        ## qui devrait être en réalité inline.
        ## mykey:
        ##   line1
        ##   line2
        ##   line3
        ## my key : line1 line2 line3
        ## la clé :fr par exemple ne rentre pas dans cas cas de figure
        ## car le split donne ["fr", "\n"]
        ##============================================================##
        elsif split.size < 2
          lines[-1] = (lines[-1] + " #{current_line.lstrip}").gsub(NEWLINE, "")
        ##============================================================##
        ## Sinon nous sommes dans le cas d'une ligne classique
        ## key: value  ou key: sans value
        ##============================================================##
        else
          key           = clean_key(key)
          spaces        = (SPACE * indent_level).to_s
          current_line  = "#{spaces}#{key}:"

          if !split[1].empty?
            value = split[1].to_s.strip
            
            ##============================================================##
            ## On est dans un block multiline qui devrait être un inline
            ## si la value commence par un " et que le nombre de " est impair
            ##============================================================##
            if (value.start_with?(DOUBLE_QUOTE) && value.count(DOUBLE_QUOTE).odd?) || (value.start_with?(SIMPLE_QUOTE) && value.count(SIMPLE_QUOTE).odd?)
              weirdblock        = true
              weirdblock_indent = indent_level
            else
              value = clean_value(split[1])
            end
            current_line += " #{value}"
          end

          ##============================================================##
          ## Fusion de la clé et de la valeur nettoyées pour former la ligne nettoyée
          ##============================================================##
          lines << current_line
        end

        ##============================================================##
        ## On incrémente le numéro de ligne
        ##============================================================##
        line_index += 1
      end

      ##============================================================##
      ## On fini le fichier avec un retour à la ligne et on supprime
      ## les espaces sur les lignes "vides" + les doubles espaces
      ## avec la même technique que plus haut
      ##============================================================##
      lines += [""]
      lines = lines.map {|l| (l.strip.empty? ? "" : l).to_s.gsub(/(?<=\S)\s+/, SPACE) }
      File.write(file_path, lines.join(NEWLINE))
    end    

    ##============================================================##
    ## On nettoie la clé
    ## =================
    ## - on la met force en string pour éviter tout problème avec
    ## les gsub (si c'est un integer par exemple)
    ## - on regarde si c'est un integer
    ## - on emlève les quotes s'ils sont présents
    ## - on remets les quotes si c'est une clé réservée ou un integer
    ##  /\A(['“‘”’"])(.*)\1\z/
    ## \A :         Ceci est une ancre qui correspond au début de la chaîne. Elle s'assure que notre motif commence au tout début de la chaîne.
    ## (['“‘”’"]) : Ceci est un groupe de capture qui correspond à un seul caractère de guillemet. Il peut correspondre à l'un des caractères spécifiés entre les crochets, qui incluent divers types de guillemets simples et doubles. Le caractère correspondant est "capturé" et peut être réutilisé dans le reste de l'expression régulière grâce à la référence arrière \1.
    ## (.*) :       Ceci est un autre groupe de capture qui correspond à zéro ou plusieurs de n'importe quel caractère (sauf un saut de ligne, sauf si l'option m est activée). Il "capture" toute la chaîne entre les guillemets que nous avons capturés précédemment.
    ## \1 :         Ceci est une référence arrière au premier groupe de capture. Elle correspond au même caractère que celui que nous avons capturé avec notre premier groupe de capture. Cela garantit que nous avons le même caractère de guillemet à la fin de la chaîne que celui que nous avons au début.
    ## \z :         Ceci est une ancre qui correspond à la fin de la chaîne. Elle s'assure que notre motif correspond à la toute fin de la chaîne, garantissant ainsi que les guillemets encadrent toute la chaîne.
    ##
    ## Ensuite, dans le deuxième argument de gsub, nous utilisons \2 pour nous référer au contenu capturé par le deuxième groupe de capture, ce qui nous permet d'obtenir la chaîne sans les guillemets :
    ##============================================================##
    def clean_key(key)
      key    = key.to_s
      is_int = key =~ /\A[-+]?\d+\z/
      key    = key.gsub(/\A(['“”‘’"]?)(.*)\1\z/, '\2')
      key    = "\"#{key}\"" if key.in?(RESERVED_KEYS) || is_int
      key
    end

    ##============================================================##
    ## Dans le cas des "inblock", on n'a pas besoin de mettre des
    ## quotes autour de la value. Car c'est déjà execpt dans le
    ## language YML
    ##============================================================##
    def clean_value(value, with_quotes_verif = true)
      ##============================================================##
      ## On met la value en string pour éviter tout problème dans
      ## les taitement suivants
      ##============================================================##
      value = value.to_s
      
      ##============================================================##
      ## On enlève les retours à la ligne en fin de value si il y 
      ## en a un. (À faire avant le strip pour le cas où cela fini
      ## par un espace pour un retour à la ligne)
      ##============================================================##
      value = value[0..-2] if value.end_with?(NEWLINE)

      ##============================================================##
      ## On enlève tous les tabs, retours chariot, form feed,
      ## \t : correspond à une tabulation
      ## \r : correspond à un retour chariot (carriage return)
      ## \f : correspond à un form feed
      ## \v : correspond à une tabulation verticale
      ## On garde les \n
      ##============================================================##
      value = value.gsub(/[\t\r\f\v]+/, "")
      
      ##============================================================##
      ## On remplace les multiples espaces par un seul espace
      ##============================================================##
      value = value.gsub(/ {2,}/, SPACE)
      
      ##============================================================##
      ## On strip la value pour enlever les espaces en début et fin
      ##============================================================##
      value = value.strip
      
      ##============================================================##
      ## Remplacement des guillemets spéciaux par des guillemets 
      ## simples standards
      ##============================================================##
      value = value.gsub(WEIRD_QUOTES_REGEX, SIMPLE_QUOTE)

      ##============================================================##
      ## Suppression des quotes entourant la valeur, 
      ## s'ils sont présents. On va remetre par la suite si besoin
      ##============================================================##
      value = value[1..-2] if (value.start_with?(DOUBLE_QUOTE) && value.end_with?(DOUBLE_QUOTE)) || (value.start_with?(SIMPLE_QUOTE) && value.end_with?(SIMPLE_QUOTE))
        

      ##============================================================##
      ## On traite les emojis qui serait sous forme \U0001F600
      ##============================================================##
      value = value.gsub(/\\U([0-9A-Fa-f]{8})/) { [::Regexp.last_match(1).to_i(16)].pack("U*") }

      ##============================================================##
      ## Gestion des cas où la valeur doit être entourée de guillemets
      ## if :
      ## value.include?(": ")                   => key: text with : here
      ## value.include?(" #")                   => key: text with # here
      ## value.include?(NEWLINE)                => key: Ligne 1\nLigne 2\nLigne 3
      ## value.include?('\n')                   => key: Ligne 1"\n"Ligne 2"\n"Ligne 3
      ## value.start_with?(*YML_SPECIAL_CHARS)  => key: @text
      ## value.end_with?(":")                   => key: text:
      ## value.in?(RESERVED_KEYS)               => key: YES
      ## value.start_with?(SPACE)               => key: ' text'
      ## value.end_with?(SPACE)                 => key: text '
      ## else :
      ## gestiion de "" et " ". Pas possible d'avoir plus d'espaces
      ## car on a déjà suppriné les doubles espaces
      ##============================================================##
      if value.present?
        value = "\"#{value}\"" if (value.include?(": ") || 
                                  value.include?(" #") ||
                                  value.include?(NEWLINE) || 
                                  value.include?('\n') || 
                                  value.start_with?(*YML_SPECIAL_CHARS) ||
                                  value.end_with?(":") ||
                                  value.in?(RESERVED_KEYS) ||
                                  value.start_with?(SPACE) || 
                                  value.end_with?(SPACE)) &&
                                  with_quotes_verif == true
        
      else
        value = "\"#{value}\""
      end
      value
    end

    ##============================================================##
    ## Deep transform values
    ##============================================================##
    def deep_transform_values(hash, &block)
      hash.transform_values do |value|
        if value.is_a?(Hash)
          deep_transform_values(value, &block)
        else
          block.call(value)
        end
      end
    end

    ##============================================================##
    ## Pour trier de façon récursive un hash par clé et en
    ## gérant la case
    ##============================================================##
    def sort_by_key(hash, recursive = false, &block)
      block ||= proc {|a, b| a.to_s.downcase.gsub(DOUBLE_QUOTE, "") <=> b.to_s.downcase.gsub(DOUBLE_QUOTE, "") }
      hash.keys.sort(&block).each_with_object({}) do |key, seed|
        seed[key] = hash[key]
        seed[key] = sort_by_key(seed[key], true, &block) if recursive && seed[key].is_a?(Hash)
      end
    end

    def parse_xml(file_path)
      nested_hash = {}
      inblock     = nil
      last_keys   = []
    
      ##============================================================##
      ## On pase sur chaque ligne du fichier pour en créer un hash.
      ## On met les blocks multiline dans un array pour récupérer
      ## toutes les valeurs et le type de formatage puis on passera
      ## sur chacun de ces arrays par la suite pour les transformer
      ## dans la string correspondante
      ##============================================================##
      File.foreach(file_path) do |line|
        ##============================================================##
        ## Détection du niveau d'indentation
        ##============================================================##
        indent_level = line[/\A */].size

        ##============================================================##
        ## Détection des lignes blanches (dans les blocks multiline)
        ##============================================================##
        blank_line = line.gsub(NEWLINE, "").empty?
        
        ##============================================================##
        ## Découpage de la ligne en clé et valeur
        ##============================================================##
        split   = line.strip.split(":", 2)
        key     = split[0].to_s.strip
        inblock = nil if !inblock.nil? && !blank_line && indent_level <= inblock
        
        
        ##============================================================##
        ## On détermine le niveau de clé en fonction de l'indentation
        ##============================================================##
        last_keys = last_keys[0, (blank_line ? inblock + INDENT_SIZE : indent_level) / INDENT_SIZE]
        
        ##============================================================##
        ## Si on est dans un block, on récupère la dernière clé et on
        ## ajoute la ligne au résultat
        ##============================================================##
        if !inblock.nil?
          current_key           = last_keys.last
          parent_keys           = last_keys[0..-2]
          result                = parent_keys.reduce(nested_hash) {|hash, k| hash[k] }
          result[current_key][1] << line.strip
        ##============================================================##
        ## Si on est sur une clé de type multiline
        ## ajoute la ligne au résultat. Nous n'avons plus le >
        ## car il est transformé dans le initial_yml_clean en | (avec
        ## un retour à la lgine à la fin)
        ##============================================================##
        elsif line.gsub("#{key}:", "").strip.start_with?("|")
          ##============================================================##
          ## il faut différencier dans quel type de block nous sommmes
          ## Normalement il y a que | et |- mais si j'ai déjà vu 
          ## aussi |2- où le 2 signifie l'intentation supplémentaire
          ## à utiliser.
          ##============================================================#
          inblock     = indent_level
          result      = last_keys.reduce(nested_hash) {|hash, k| hash[k] }
          result[key] = [line.gsub("#{key}:", "").strip, []]
          last_keys << key
        ##============================================================##
        ## Sinon nous sommes dans le cas d'une ligne classique
        ## key: value  ou key: sans value
        ##============================================================##
        else
          value  = split[1].to_s.strip
          result = last_keys.reduce(nested_hash) {|hash, k| hash[k] }
          if value.empty?
            result[key] = {}
            last_keys << key
          else
            result[key] = value.strip == "null" ? nil : value
          end
        end
      end

      ##============================================================##
      ## On repasse sur chaque value puis on traite si c'est un has
      ## |   avec retour à la ligne final
      ## |4  avec retour à la ligne final et indentation de 4
      ## |-  sans retour à la ligne final
      ## |4- sans retour à la ligne final et indentation de 4
      ##============================================================##
      deep_transform_values(nested_hash) do |value|
        if value.is_a?(Array) 
          style_type   = value[0]
          indent_supp  = style_type.scan(/\d+/).first&.to_i || 0
          indent_supp  = [indent_supp - INDENT_SIZE, 0].max
          value[1]     = value[1].map {|l| "#{SPACE * indent_supp}#{l}" }
          text         = value[1].join(NEWLINE)
          modifier     = style_type[-1]

          case modifier
          when "+"
            text << NEWLINE unless text.end_with?(NEWLINE)
          when "-"
            text.chomp!
          else # pour le cas "|" sans + ou -
            text << NEWLINE unless text.end_with?(NEWLINE)
          end
          text
        else
          value
        end
      end
    end


  end
end