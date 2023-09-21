require "spec_helper"
require "immosquare-yaml"
require "yaml"
require "json"


describe ImmosquareYaml do
  let(:sample_yaml_path)  { "spec/fixtures/sample.en.yml" }
  let(:sample_output_path) { "spec/output/sample_cleaned.en.yml" }

  describe ".parse" do
    it "parses a YAML file into a Ruby hash" do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      expect(hash).to(be_a(Hash))
    end
  end

  describe ".clean" do
    it "cleans a YAML file" do
      ImmosquareYaml.clean(sample_yaml_path, :output => sample_output_path)
      expect { YAML.load_file(sample_yaml_path) }.not_to(raise_error)
    end
  end

  describe ".dump" do
    it "creates a YAML file from a Ruby hash" do
      data = JSON.parse(File.read("spec/fixtures/sample.json"))
      yaml = ImmosquareYaml.dump(data)
      expect { YAML.safe_load(yaml) }.not_to(raise_error)
    end
  end
end
