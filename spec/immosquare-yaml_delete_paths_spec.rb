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
    Dir.mktmpdir("immosquare-yaml-delete-spec-") do |dir|
      @tmp_dir = dir
      example.run
    end
  end

  let(:tmp_dir) { @tmp_dir }

  def write_yaml(name, content)
    path = File.join(tmp_dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  describe(".delete_paths") do
    it("removes a single leaf and rewrites the file") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          app:
            leases:
              title: "Baux"
              statuses:
                active: "Actif"
                archived: "Archivé"
      YAML

      report = ImmosquareYaml.delete_paths(path, "fr.app.leases.statuses.archived")

      expect(report).to(eq(:deleted => ["fr.app.leases.statuses.archived"], :not_found => []))
      reparsed = ImmosquareYaml.parse(path)
      expect(reparsed.dig("fr", "app", "leases", "statuses")).to(eq("active" => "Actif"))
    end

    it("accepts an Array of paths and reports deleted vs not_found") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          a: "un"
          b: "deux"
          c: "trois"
      YAML

      report = ImmosquareYaml.delete_paths(path, ["fr.a", "fr.zzz", "fr.c"])

      expect(report[:deleted]).to(match_array(["fr.a", "fr.c"]))
      expect(report[:not_found]).to(eq(["fr.zzz"]))
      expect(ImmosquareYaml.parse(path)).to(eq("fr" => {"b" => "deux"}))
    end

    it("prunes empty parent hashes recursively") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          deep:
            nested:
              only: "value"
          other: "kept"
      YAML

      ImmosquareYaml.delete_paths(path, "fr.deep.nested.only")

      reparsed = ImmosquareYaml.parse(path)
      expect(reparsed).to(eq("fr" => {"other" => "kept"}))
    end

    it("prunes empty parents up to the root") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          only: "value"
      YAML

      ImmosquareYaml.delete_paths(path, "fr.only")

      ##============================================================##
      ## "fr" devient vide après suppression de "only" : le pruning
      ## récursif le retire aussi, le hash final est {}.
      ##============================================================##
      expect(ImmosquareYaml.parse(path)).to(eq({}))
    end

    it("supports reserved-key segments quoted in the dot-path") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          statuses:
            "yes": "Oui"
            "no": "Non"
      YAML

      report = ImmosquareYaml.delete_paths(path, "fr.statuses.\"yes\"")

      expect(report[:deleted]).to(eq(["fr.statuses.\"yes\""]))
      expect(ImmosquareYaml.parse(path)).to(eq("fr" => {"statuses" => {"no" => "Non"}}))
    end

    it("supports numeric segments quoted in the dot-path") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          counts:
            "1": "one"
            "2": "two"
      YAML

      report = ImmosquareYaml.delete_paths(path, "fr.counts.\"1\"")

      expect(report[:deleted]).to(eq(["fr.counts.\"1\""]))
      expect(ImmosquareYaml.parse(path)).to(eq("fr" => {"counts" => {"2" => "two"}}))
    end

    it("writes to a separate output path when given") do
      src = write_yaml("fr.yml", <<~YAML)
        fr:
          a: "un"
          b: "deux"
      YAML
      dst = File.join(tmp_dir, "out.yml")

      ImmosquareYaml.delete_paths(src, "fr.a", :output => dst)

      ##============================================================##
      ## Source must be untouched, destination must hold the result.
      ##============================================================##
      expect(ImmosquareYaml.parse(src)).to(eq("fr" => {"a" => "un", "b" => "deux"}))
      expect(ImmosquareYaml.parse(dst)).to(eq("fr" => {"b" => "deux"}))
    end

    it("returns false when the file does not exist") do
      expect(ImmosquareYaml.delete_paths(File.join(tmp_dir, "nope.yml"), "fr.a")).to(eq(false))
    end

    it("treats every path as not_found when the file is empty") do
      path = write_yaml("empty.yml", "")

      report = ImmosquareYaml.delete_paths(path, ["fr.a", "fr.b"])

      expect(report).to(eq(:deleted => [], :not_found => ["fr.a", "fr.b"]))
    end

    it("preserves the rest of the file format on rewrite") do
      path = write_yaml("fr.yml", <<~YAML)
        fr:
          multiline: |
            ligne 1
            ligne 2
          quoted: "yes"
          plain: "Bonjour"
      YAML

      ImmosquareYaml.delete_paths(path, "fr.plain")

      content = File.read(path)
      expect(content).to(include("multiline: |"))
      expect(content).to(include("ligne 1"))
      expect(content).to(include("quoted: \"yes\""))
      expect(content).not_to(include("plain:"))
    end
  end
end
