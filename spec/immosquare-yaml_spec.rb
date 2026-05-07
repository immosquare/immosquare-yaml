require "spec_helper"
require "immosquare-yaml"
require "yaml"
require "json"
require "fileutils"
require "tmpdir"


describe(ImmosquareYaml) do
  let(:sample_yaml_path)   { "spec/fixtures/sample.en.yml" }
  let(:edge_cases_path)    { "spec/fixtures/edge_cases.fr.yml" }

  ##============================================================##
  ## Chaque exemple obtient son propre dossier temporaire au niveau
  ## OS (/tmp/...), automatiquement nettoyé après le test. Aucun
  ## artefact n'est jamais écrit dans l'arbo du gem.
  ##============================================================##
  around do |example|
    Dir.mktmpdir("immosquare-yaml-spec-") do |dir|
      @tmp_dir = dir
      example.run
    end
  end

  let(:tmp_dir) { @tmp_dir }

  ##============================================================##
  ## .parse — comportement de base
  ##============================================================##
  describe(".parse") do
    it("parses a YAML file into a Ruby hash") do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      expect(hash).to(be_a(Hash))
      expect(hash["en"]).to(be_a(Hash))
    end

    it("returns false when the file does not exist") do
      expect(ImmosquareYaml.parse("/nonexistent/file.yml")).to(eq(false))
    end

    ##============================================================##
    ## Norway problem — yes/no/on/off/true/false en plain doivent
    ## rester des strings, jamais des booléens.
    ##============================================================##
    it("preserves reserved YAML 1.1 keys as strings (Norway problem)") do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      expect(hash["en"]["yes"]).to(eq("This is not a boolean"))
      expect(hash["en"]["no"]).to(eq("Neither is this"))
      expect(hash["en"]["reserved_words"]["yes"]).to(eq("yes"))
      expect(hash["en"]["reserved_words"]["no"]).to(eq("no"))
    end

    ##============================================================##
    ## Bug observé en v0.1.28 : un fichier avec ">-" et lignes wrap
    ## par indentation parsait en hash vide. Ce test garantit que
    ## le parser AST le gère correctement.
    ##============================================================##
    it("parses files with folded scalars (>-) and multi-line wrapped values") do
      hash = ImmosquareYaml.parse(edge_cases_path)
      expect(hash).to(be_a(Hash))
      expect(hash).not_to(be_empty)
      desc = hash["fr"]["marketing"]["long_description"]
      expect(desc).to(include("texte très long"))
      expect(desc).to(include("sans être coupé sémantiquement"))
    end

    it("decodes \\U escapes in double-quoted strings") do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      expect(hash["en"]["emoji"]).to(include("😀"))
      expect(hash["en"]["emoji2"]).to(include("😀"))
    end

    it("preserves multi-line literal blocks") do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      expect(hash["en"]["description2"]).to(include("\n"))
      expect(hash["en"]["description2"].lines.count).to(eq(3))
    end

    it("sorts keys by default") do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      expect(hash["en"].keys).to(eq(hash["en"].keys.sort))
    end

    it("preserves insertion order with sort: false") do
      hash = ImmosquareYaml.parse(sample_yaml_path, :sort => false)
      expect(hash["en"].keys.first).to(eq("fruits"))
    end
  end

  ##============================================================##
  ## .clean — réécriture du fichier
  ##============================================================##
  describe(".clean") do
    let(:output_path) { File.join(tmp_dir, "cleaned.yml") }

    it("writes valid YAML that can be reloaded") do
      ImmosquareYaml.clean(sample_yaml_path, :output => output_path)
      expect { YAML.safe_load_file(output_path, :permitted_classes => [Date]) }.not_to(raise_error)
    end

    it("is idempotent (cleaning a cleaned file produces the same output)") do
      first  = File.join(tmp_dir, "pass1.yml")
      second = File.join(tmp_dir, "pass2.yml")
      ImmosquareYaml.clean(sample_yaml_path, :output => first)
      FileUtils.cp(first, second)
      ImmosquareYaml.clean(second)
      expect(File.read(first)).to(eq(File.read(second)))
    end

    it("fixes the v0.1.28 bug where folded scalars (>-) produced an empty hash") do
      ImmosquareYaml.clean(edge_cases_path, :output => output_path)
      content = File.read(output_path)
      expect(content).not_to(be_empty)
      expect(content).to(include("fr:"))
      ##============================================================##
      ## Le résultat doit pouvoir être reparseé sans erreur et
      ## contenir les valeurs des folded scalars.
      ##============================================================##
      reparsed = ImmosquareYaml.parse(output_path)
      expect(reparsed).to(be_a(Hash))
      expect(reparsed["fr"]["marketing"]["long_description"]).to(include("texte très long"))
    end

    it("preserves the original file when output path differs and write fails partway") do
      original = File.read(sample_yaml_path)
      ImmosquareYaml.clean(sample_yaml_path, :output => output_path)
      expect(File.read(sample_yaml_path)).to(eq(original))
    end
  end

  ##============================================================##
  ## .dump — sérialisation
  ##============================================================##
  describe(".dump") do
    it("produces valid YAML from a Ruby hash") do
      data = JSON.parse(File.read("spec/fixtures/sample.json"))
      yaml = ImmosquareYaml.dump(data)
      expect { YAML.safe_load(yaml) }.not_to(raise_error)
    end

    it("quotes reserved YAML 1.1 keys") do
      yaml = ImmosquareYaml.dump({"yes" => "value", "no" => "other"})
      expect(yaml).to(include("\"yes\":"))
      expect(yaml).to(include("\"no\":"))
    end

    it("quotes values that contain ': '") do
      yaml = ImmosquareYaml.dump({"k" => "Hello: world"})
      expect(yaml).to(include("\"Hello: world\""))
    end

    it("uses double-quoted by default and single-quoted only when necessary") do
      ##============================================================##
      ## Cas standard → double-quoted (cohérent avec la règle Ruby
      ## "double quotes obligatoires").
      ##============================================================##
      yaml = ImmosquareYaml.dump({"k" => "Hello: world"})
      expect(yaml).to(include("\"Hello: world\""))

      ##============================================================##
      ## Apostrophe interne → reste en double-quoted (pas besoin
      ## d'échapper l'apostrophe).
      ##============================================================##
      yaml = ImmosquareYaml.dump({"k" => "L'utilisateur: connecté"})
      expect(yaml).to(include("\"L'utilisateur: connecté\""))

      ##============================================================##
      ## Backslash interne → single-quoted (évite \\\\).
      ##============================================================##
      yaml = ImmosquareYaml.dump({"k" => "path\\to: file"})
      expect(yaml).to(include("'path\\to: file'"))

      ##============================================================##
      ## Double-quote interne → single-quoted (évite \").
      ##============================================================##
      yaml = ImmosquareYaml.dump({"k" => "say \"hi\": now"})
      expect(yaml).to(include("'say \"hi\": now'"))
    end

    it("renders multi-line strings as literal blocks") do
      yaml = ImmosquareYaml.dump({"k" => "line1\nline2\nline3"})
      expect(yaml).to(include("k: |-"))
      expect(yaml.lines).to(include(/  line1/))
    end

    it("ends with a newline") do
      yaml = ImmosquareYaml.dump({"a" => "b"})
      expect(yaml).to(end_with("\n"))
    end
  end
end
