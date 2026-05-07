require "spec_helper"
require "immosquare-yaml"
require "yaml"
require "fileutils"
require "date"
require "tmpdir"


describe("ImmosquareYaml — edge cases") do
  let(:fixture) { "spec/fixtures/edge_cases.fr.yml" }
  let(:tmp_dir) { @tmp_dir }
  let(:work)    { File.join(tmp_dir, "edge.yml") }

  ##============================================================##
  ## Dossier temporaire OS-level, auto-nettoyé. Aucun artefact
  ## n'est jamais écrit dans l'arbo du gem.
  ##============================================================##
  around do |example|
    Dir.mktmpdir("immosquare-yaml-edge-") do |dir|
      @tmp_dir = dir
      FileUtils.cp(fixture, File.join(dir, "edge.yml"))
      example.run
    end
  end

  ##============================================================##
  ## Helper : normalise les apostrophes typographiques pour
  ## comparer un hash original avec sa version cleanée
  ## (la normalisation `’` → `'` est une feature du gem).
  ##============================================================##
  def normalize_quotes(v)
    case v
    when String then v.gsub(/[‘’]/, "'").gsub(/[“”]/, '"')
    when Hash   then v.transform_values {|x| normalize_quotes(x) }
    when Array  then v.map {|x| normalize_quotes(x) }
    else             v
    end
  end

  ##============================================================##
  ## Sanity : tout le fichier doit pouvoir être parsé, cleaned,
  ## relu via Psych natif sans erreur.
  ##============================================================##
  describe("global pipeline") do
    it("parses without error") do
      expect(ImmosquareYaml.parse(work)).to(be_a(Hash))
    end

    it("cleans without error") do
      expect(ImmosquareYaml.clean(work)).to(eq(true))
    end

    it("produces YAML that Psych can safely reload") do
      ImmosquareYaml.clean(work)
      expect { YAML.safe_load_file(work, :permitted_classes => [Date]) }.not_to(raise_error)
    end

    it("is idempotent (clean(clean(x)) == clean(x))") do
      pass2 = File.join(tmp_dir, "pass2.yml")
      ImmosquareYaml.clean(work)
      FileUtils.cp(work, pass2)
      ImmosquareYaml.clean(pass2)
      expect(File.read(work)).to(eq(File.read(pass2)))
    end

    it("preserves data after a parse/clean/parse round-trip (modulo intentional normalization)") do
      orig = ImmosquareYaml.parse(work)
      ImmosquareYaml.clean(work)
      cleaned = ImmosquareYaml.parse(work)

      ##============================================================##
      ## On normalise nous-mêmes les typographic quotes côté orig
      ## pour comparer le reste : la normalisation `'` est une
      ## feature documentée du gem (cf. helper normalize_quotes).
      ##============================================================##
      expect(normalize_quotes(orig)).to(eq(cleaned))
    end
  end

  ##============================================================##
  ## Norway problem : les valeurs/clés réservées YAML 1.1 doivent
  ## rester des strings, jamais devenir des booléens.
  ##============================================================##
  describe("Norway problem") do
    let(:hash) { ImmosquareYaml.parse(work)["fr"] }

    it("keeps reserved keys at the top level") do
      expect(hash["yes"]).to(eq("Une valeur"))
      expect(hash["no"]).to(eq("Autre valeur"))
    end

    it("keeps reserved values as strings") do
      expect(hash["reserved_values"]["a"]).to(eq("yes"))
      expect(hash["reserved_values"]["b"]).to(eq("no"))
      expect(hash["reserved_values"]["c"]).to(eq("on"))
      expect(hash["reserved_values"]["d"]).to(eq("off"))
      expect(hash["reserved_values"]["e"]).to(eq("true"))
      expect(hash["reserved_values"]["f"]).to(eq("false"))
    end

    it("re-quotes reserved keys when dumping") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/^\s+"yes":/))
      expect(content).to(match(/^\s+"no":/))
    end

    it("re-quotes reserved values when dumping (so reload returns strings)") do
      ImmosquareYaml.clean(work)
      reloaded = YAML.safe_load_file(work, :permitted_classes => [Date])
      expect(reloaded["fr"]["reserved_values"]["a"]).to(eq("yes"))
      expect(reloaded["fr"]["reserved_values"]["e"]).to(eq("true"))
      expect(reloaded["fr"]["reserved_values"]["f"]).to(eq("false"))
    end
  end

  ##============================================================##
  ## Clés numériques — doivent être quotées et triées comme strings.
  ##============================================================##
  describe("numeric keys") do
    it("preserves numeric keys as quoted strings") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/"1":/))
      expect(content).to(match(/"10":/))
      expect(content).to(match(/"2":/))
    end

    it("exposes them as String keys in the parsed hash") do
      hash = ImmosquareYaml.parse(work)["fr"]["steps"]
      expect(hash.keys.sort).to(eq(["1", "10", "2"]))
    end
  end

  ##============================================================##
  ## Hashs profonds — accès direct doit fonctionner après clean.
  ##============================================================##
  describe("deep nesting") do
    it("preserves 5-level deep values") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash.dig("fr", "app", "section", "subsection", "block", "item")).to(eq("Valeur profondément imbriquée"))
    end
  end

  ##============================================================##
  ## Interpolations Rails %{var}
  ##============================================================##
  describe("Rails interpolation") do
    it("preserves %{var} placeholders verbatim") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["greetings"]["hello"]).to(eq("Bonjour %{name}"))
      expect(hash["fr"]["greetings"]["counter"]).to(include("%{count}"))
      expect(hash["fr"]["greetings"]["multi"]).to(include("%{date}"))
      expect(hash["fr"]["greetings"]["multi"]).to(include("%{time}"))
      expect(hash["fr"]["greetings"]["multi"]).to(include("%{location}"))
    end
  end

  ##============================================================##
  ## Pluralisation Rails (zero/one/other)
  ##============================================================##
  describe("Rails pluralization") do
    it("preserves the zero/one/other structure") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)["fr"]["apples"]
      expect(hash.keys.sort).to(eq(["one", "other", "zero"]))
      expect(hash["other"]).to(eq("%{count} pommes"))
    end
  end

  ##============================================================##
  ## HTML inline avec attributs — quoting double-quoted nécessite
  ## d'échapper les " internes.
  ##============================================================##
  describe("inline HTML") do
    it("preserves HTML markup with attributes after clean") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["homepage"]["hero_html"]).to(include("<strong>NotreApp</strong>"))
      expect(hash["fr"]["homepage"]["cta_html"]).to(include('href="https://example.com"'))
      expect(hash["fr"]["homepage"]["cta_html"]).to(include('class="btn btn-primary"'))
      expect(hash["fr"]["homepage"]["legal_html"]).to(include('href="/terms"'))
    end

    it("produces YAML that re-parses with quotes intact") do
      ImmosquareYaml.clean(work)
      reloaded = YAML.safe_load_file(work, :permitted_classes => [Date])
      expect(reloaded["fr"]["homepage"]["cta_html"]).to(include('href="https://example.com"'))
    end
  end

  ##============================================================##
  ## Emojis — escapes \U... décodés, caractères directs préservés.
  ##============================================================##
  describe("emojis") do
    it("decodes \\U escapes to actual emoji characters") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["emoji_section"]["smile_escape"]).to(include("😀"))
      expect(hash["fr"]["emoji_section"]["smile_escape"]).not_to(include("\\U"))
    end

    it("preserves direct UTF-8 emojis") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["emoji_section"]["smile_direct"]).to(include("😀"))
      expect(hash["fr"]["emoji_section"]["multiple"]).to(include("🎉"))
      expect(hash["fr"]["emoji_section"]["multiple"]).to(include("🚀"))
    end
  end

  ##============================================================##
  ## Typographic quotes — normalisation documentée.
  ##============================================================##
  describe("typographic quotes normalization") do
    it("normalizes curly apostrophe to standard apostrophe") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["typography"]["curly_apostrophe"]).to(eq("L'utilisateur s'est connecté"))
    end

    it("preserves em-dash and ellipsis (not normalized)") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["typography"]["em_dash"]).to(include("—"))
      expect(hash["fr"]["typography"]["ellipsis"]).to(include("…"))
    end
  end

  ##============================================================##
  ## Folded scalars (>-) — bug historique du parser ligne-par-ligne.
  ##============================================================##
  describe("folded scalars (>-) — historical bug") do
    it("parses long folded text into a single logical line") do
      hash = ImmosquareYaml.parse(work)
      desc = hash["fr"]["marketing"]["long_description"]
      expect(desc).to(include("Ceci est un texte très long"))
      expect(desc).to(include("sans être coupé sémantiquement"))
      expect(desc).not_to(include("\n"))
    end

    it("preserves folded HTML content") do
      hash = ImmosquareYaml.parse(work)
      html = hash["fr"]["marketing"]["very_long_html"]
      expect(html).to(include('<a href="https://example.com">'))
      expect(html).to(include("contact@example.com"))
    end
  end

  ##============================================================##
  ## Blocs littéraux (| et |-)
  ##============================================================##
  describe("literal block scalars") do
    it("preserves newlines for | (with trailing newline)") do
      hash = ImmosquareYaml.parse(work)
      val = hash["fr"]["long_form"]["paragraph_with_final_newline"]
      expect(val.lines.count).to(eq(3))
      expect(val).to(end_with("\n"))
    end

    it("strips trailing newline for |-") do
      hash = ImmosquareYaml.parse(work)
      val = hash["fr"]["long_form"]["paragraph_chomped"]
      expect(val.lines.count).to(eq(3))
      expect(val).not_to(end_with("\n"))
    end

    it("re-emits multiline content as block scalars (not flow)") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/paragraph_with_final_newline: \|/))
      expect(content).to(match(/paragraph_chomped: \|-/))
    end
  end

  ##============================================================##
  ## Listes
  ##============================================================##
  describe("lists") do
    it("preserves simple string lists") do
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["weekdays"]).to(eq(["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]))
    end

    it("preserves empty lists") do
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["empty_list"]).to(eq([]))
    end

    it("preserves lists of hashes with nil values") do
      hash = ImmosquareYaml.parse(work)
      members = hash["fr"]["team_members"]
      expect(members.size).to(eq(3))
      expect(members[2]["level"]).to(be_nil)
    end

    it("preserves deeply-nested list/hash combinations") do
      hash = ImmosquareYaml.parse(work)
      catalog = hash["fr"]["product_catalog"]
      expect(catalog[0]["tags"]).to(eq(["bestseller", "new"]))
      expect(catalog[0]["pricing"]["eur"]).to(eq(49.9))
      expect(catalog[1]["tags"]).to(eq([]))
    end
  end

  ##============================================================##
  ## Caractères spéciaux en début de valeur — chacun doit être
  ## quoté pour ne pas être confondu avec un marqueur YAML.
  ##============================================================##
  describe("special leading characters") do
    SPECIAL_KEYS = {
      "dash"         => "-tiret",
      "asterisk"     => "*étoile",
      "percent"      => "%pourcentage",
      "ampersand"    => "&esperluette",
      "hash"         => "#dièse",
      "at"           => "@arobase",
      "exclamation"  => "!exclamation",
      "question"     => "?interrogation",
      "pipe"         => "|barre",
      "bracket_open" => "[crochet",
      "angle_open"   => ">chevron",
      "colon"        => ":deux-points",
      "comma"        => ",virgule",
      "backtick"     => "`backtick"
    }.freeze

    SPECIAL_KEYS.each do |key, expected|
      it("preserves '#{key}' value through clean + reparse") do
        ImmosquareYaml.clean(work)
        hash = ImmosquareYaml.parse(work)
        expect(hash["fr"]["special_starts"][key]).to(eq(expected))
      end
    end

    it("preserves embedded double quotes") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["special_starts"]["quote_double"]).to(eq('"guillemet'))
    end

    it("preserves embedded single quotes") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["special_starts"]["quote_single"]).to(eq("'apostrophe"))
    end
  end

  ##============================================================##
  ## Patterns qui déclenchent le quoting au dump.
  ##============================================================##
  describe("quoting triggers") do
    it("quotes values with internal ': '") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/colon_internal: '.*: avec/))
    end

    it("quotes values ending with ':'") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/ends_with_colon: '.*:'/))
    end

    it("quotes values with leading/trailing whitespace") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["quoting_triggers"]["leading_space"]).to(eq(" commence par espace"))
      expect(hash["fr"]["quoting_triggers"]["trailing_space"]).to(eq("finit par espace "))
    end

    it("quotes empty strings") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/empty_string: ''/))
    end
  end

  ##============================================================##
  ## Valeurs nulles — toutes les formes sont équivalentes.
  ##============================================================##
  describe("null values") do
    it("treats null, ~ and missing as nil") do
      hash = ImmosquareYaml.parse(work)
      nullables = hash["fr"]["nullables"]
      expect(nullables["explicit_null"]).to(be_nil)
      expect(nullables["tilde_null"]).to(be_nil)
      expect(nullables["missing_value"]).to(be_nil)
    end

    it("emits 'null' literally when dumping nil values") do
      ImmosquareYaml.clean(work)
      content = File.read(work)
      expect(content).to(match(/explicit_null: null/))
    end
  end

  ##============================================================##
  ## Devises et chiffres formatés — toujours des strings.
  ##============================================================##
  describe("currencies and numbers in strings") do
    it("preserves formatted prices as strings") do
      hash = ImmosquareYaml.parse(work)
      expect(hash["fr"]["prices"]["eur"]).to(eq("1 234,56 €"))
      expect(hash["fr"]["prices"]["usd"]).to(eq("$1,234.56"))
      expect(hash["fr"]["prices"]["range"]).to(eq("De 100 € à 1 000 €"))
      expect(hash["fr"]["prices"]["discount"]).to(eq("-15 %"))
    end
  end

  ##============================================================##
  ## Conventions de nommage de clés mixées.
  ##============================================================##
  describe("key naming conventions") do
    it("preserves all naming styles after clean") do
      ImmosquareYaml.clean(work)
      hash = ImmosquareYaml.parse(work)["fr"]["naming"]
      expect(hash["snake_case_key"]).to(eq("valeur 1"))
      expect(hash["kebab-case-key"]).to(eq("valeur 2"))
      expect(hash["camelCaseKey"]).to(eq("valeur 3"))
      expect(hash["UPPER_CASE"]).to(eq("valeur 4"))
      expect(hash["with.dots"]).to(eq("valeur 5"))
      expect(hash["with spaces"]).to(eq("valeur 6"))
      expect(hash["1_starts_with_digit"]).to(eq("valeur 7"))
    end
  end
end
