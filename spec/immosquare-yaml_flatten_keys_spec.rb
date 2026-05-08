require "spec_helper"
require "immosquare-yaml"
require "fileutils"
require "tmpdir"


describe(ImmosquareYaml) do
  ##============================================================##
  ## Each example gets its own tmp dir — no artifact ever written
  ## inside the gem tree.
  ##============================================================##
  around do |example|
    Dir.mktmpdir("immosquare-yaml-flatten-spec-") do |dir|
      @tmp_dir = dir
      example.run
    end
  end

  let(:tmp_dir) { @tmp_dir }

  ##============================================================##
  ## Helper to write a YAML fixture inside tmp_dir.
  ##============================================================##
  def write_yaml(name, content)
    path = File.join(tmp_dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe(".flatten_keys") do
    it("flattens a classic i18n YAML into sorted dot-paths") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          app:
            leases:
              title: "Baux"
              statuses:
                active: "Actif"
                archived: "Archivé"
      YAML

      expect(ImmosquareYaml.flatten_keys(path)).to(eq([
        "fr.app.leases.statuses.active",
        "fr.app.leases.statuses.archived",
        "fr.app.leases.title"
      ]))
    end

    it("quotes reserved YAML 1.1 keys in the path") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          statuses:
            "true": "Oui"
            "false": "Non"
            "yes": "Si"
            normal: "ok"
      YAML

      paths = ImmosquareYaml.flatten_keys(path)
      expect(paths).to(include("fr.statuses.\"true\""))
      expect(paths).to(include("fr.statuses.\"false\""))
      expect(paths).to(include("fr.statuses.\"yes\""))
      expect(paths).to(include("fr.statuses.normal"))
    end

    it("quotes purely numeric keys in the path") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          counts:
            "42": "quarante-deux"
            "0": "zéro"
            label: "ok"
      YAML

      paths = ImmosquareYaml.flatten_keys(path)
      expect(paths).to(include("fr.counts.\"42\""))
      expect(paths).to(include("fr.counts.\"0\""))
      expect(paths).to(include("fr.counts.label"))
    end

    it("returns an empty array for a missing file") do
      expect(ImmosquareYaml.flatten_keys("/nonexistent/file.yml")).to(eq([]))
    end

    it("returns an empty array for an empty file") do
      path = write_yaml("empty.yml", "")
      expect(ImmosquareYaml.flatten_keys(path)).to(eq([]))
    end

    ##============================================================##
    ## with_values: true — every leaf with its value, including
    ## nil and non-string types.
    ##============================================================##
    it("returns [path, value] pairs when with_values: true") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          a: "string value"
          b: 42
          c: null
          d: "yes"
      YAML

      pairs = ImmosquareYaml.flatten_keys(path, :with_values => true)
      expect(pairs).to(include(["fr.a", "string value"]))
      expect(pairs).to(include(["fr.b", 42]))
      expect(pairs).to(include(["fr.c", nil]))
      ##============================================================##
      ## Plain "yes" stays a String because of the Norway problem.
      ##============================================================##
      expect(pairs).to(include(["fr.d", "yes"]))
    end

    it("treats Array values as leaves (no descent)") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          fruits:
            - apple
            - orange
            - banana
      YAML

      paths = ImmosquareYaml.flatten_keys(path)
      expect(paths).to(eq(["fr.fruits"]))

      pairs = ImmosquareYaml.flatten_keys(path, :with_values => true)
      expect(pairs).to(eq([["fr.fruits", ["apple", "orange", "banana"]]]))
    end

    ##============================================================##
    ## Multi-file input: Array of paths, global dedup + sort.
    ##============================================================##
    it("merges, dedupes and sorts paths across multiple files (Array input)") do
      fr = write_yaml("fr.yml", <<~YAML)
        fr:
          app:
            title: "Titre"
            body: "Corps"
      YAML
      en = write_yaml("en.yml", <<~YAML)
        en:
          app:
            title: "Title"
            body: "Body"
      YAML

      paths = ImmosquareYaml.flatten_keys([fr, en])
      expect(paths).to(eq([
        "en.app.body",
        "en.app.title",
        "fr.app.body",
        "fr.app.title"
      ]))
    end

    ##============================================================##
    ## With with_values, every entry is kept even when several
    ## files share the same path (typical case: same key in fr and
    ## en — different locale → different top-level path anyway).
    ##============================================================##
    it("keeps duplicate paths across files when with_values: true") do
      shared_a = write_yaml("a.yml", "shared:\n  key: \"first\"\n")
      shared_b = write_yaml("b.yml", "shared:\n  key: \"second\"\n")

      pairs = ImmosquareYaml.flatten_keys([shared_a, shared_b], :with_values => true)
      expect(pairs).to(eq([
        ["shared.key", "first"],
        ["shared.key", "second"]
      ]))
    end

    it("returns [path, file] tuples when with_file: true") do
      fr = write_yaml("fr.yml", "fr:\n  hello: \"Bonjour\"\n")
      en = write_yaml("en.yml", "en:\n  hello: \"Hello\"\n")

      tuples = ImmosquareYaml.flatten_keys([fr, en], :with_file => true)
      expect(tuples).to(eq([
        ["en.hello", en],
        ["fr.hello", fr]
      ]))
    end

    it("returns [path, value, file] tuples when with_values + with_file") do
      fr = write_yaml("fr.yml", "fr:\n  hello: \"Bonjour\"\n")

      tuples = ImmosquareYaml.flatten_keys(fr, :with_values => true, :with_file => true)
      expect(tuples).to(eq([["fr.hello", "Bonjour", fr]]))
    end

    it("silently skips invalid paths and keeps valid ones") do
      fr = write_yaml("fr.yml", "fr:\n  hello: \"Bonjour\"\n")

      paths = ImmosquareYaml.flatten_keys([fr, "/nonexistent/file.yml"])
      expect(paths).to(eq(["fr.hello"]))
    end

    ##============================================================##
    ## flatten_keys also accepts a Hash directly (no I/O).
    ##============================================================##
    it("accepts a Hash directly") do
      hash  = {"fr" => {"app" => {"title" => "Titre", "body" => "Corps"}}}
      paths = ImmosquareYaml.flatten_keys(hash)
      expect(paths).to(eq(["fr.app.body", "fr.app.title"]))
    end

    it("accepts a Hash with values and a nil file source") do
      hash   = {"fr" => {"hello" => "Bonjour"}}
      tuples = ImmosquareYaml.flatten_keys(hash, :with_values => true, :with_file => true)
      expect(tuples).to(eq([["fr.hello", "Bonjour", nil]]))
    end

    ##============================================================##
    ## Empty nested Hash: structural noise (no translatable leaf),
    ## must be skipped entirely.
    ##============================================================##
    it("skips empty nested Hash values") do
      hash  = {"fr" => {"empty" => {}, "filled" => {"k" => "v"}}}
      paths = ImmosquareYaml.flatten_keys(hash)
      expect(paths).to(eq(["fr.filled.k"]))
    end

    it("quotes reserved and numeric keys when flattening a Hash") do
      hash  = {"fr" => {"statuses" => {"yes" => "Oui", "42" => "quarante-deux"}}}
      paths = ImmosquareYaml.flatten_keys(hash)
      expect(paths).to(include("fr.statuses.\"yes\""))
      expect(paths).to(include("fr.statuses.\"42\""))
    end
  end

  ##============================================================##
  ## parse_path : symmetric inverse of the quoting done by
  ## flatten_keys. The result must be usable as-is with Hash#dig
  ## on a hash returned by ImmosquareYaml.parse.
  ##============================================================##
  describe(".parse_path") do
    it("splits a plain dot path") do
      expect(ImmosquareYaml.parse_path("fr.app.title")).to(eq(["fr", "app", "title"]))
    end

    it("unquotes reserved-word segments") do
      expect(ImmosquareYaml.parse_path("fr.statuses.\"yes\"")).to(eq(["fr", "statuses", "yes"]))
    end

    it("unquotes numeric segments") do
      expect(ImmosquareYaml.parse_path("fr.counts.\"42\"")).to(eq(["fr", "counts", "42"]))
    end

    it("returns segments usable with Hash#dig on a parsed YAML") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          statuses:
            "yes": "Oui"
            "42": "quarante-deux"
            normal: "ok"
      YAML
      parsed = ImmosquareYaml.parse(path)

      expect(parsed.dig(*ImmosquareYaml.parse_path("fr.statuses.\"yes\""))).to(eq("Oui"))
      expect(parsed.dig(*ImmosquareYaml.parse_path("fr.statuses.\"42\""))).to(eq("quarante-deux"))
      expect(parsed.dig(*ImmosquareYaml.parse_path("fr.statuses.normal"))).to(eq("ok"))
    end

    it("is symmetric with flatten_keys (round-trip)") do
      hash   = {"fr" => {"statuses" => {"yes" => "Oui", "42" => "x", "normal" => "ok"}}}
      paths  = ImmosquareYaml.flatten_keys(hash)
      values = paths.map {|p| hash.dig(*ImmosquareYaml.parse_path(p)) }
      expect(values).to(eq(["x", "Oui", "ok"]))
    end
  end
end
