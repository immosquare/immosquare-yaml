require "spec_helper"
require "immosquare-yaml"

describe ImmosquareYaml do
  let(:sample_yaml_path) { "spec/fixtures/sample.en.yml" }
  let(:sample_hash) { {"a" => 1, "b" => 2} }

  describe ".parse" do
    it "parses a YAML file into a Ruby hash" do
      hash = ImmosquareYaml.parse(sample_yaml_path)
      puts hash
      # expect(hash).to(be_a(Hash))
    end

    # it "returns a sorted hash by default" do
    #   hash = ImmosquareYaml.parse(sample_yaml_path)
    #   expect(hash.keys).to(eq(hash.keys.sort))
    # end

    # it "does not sort the hash if :sort => false is passed" do
    #   hash = ImmosquareYaml.parse(sample_yaml_path, :sort => false)
    #   expect(hash.keys).not_to(eq(hash.keys.sort))
    # end
  end

  # describe ".clean" do
  #   it "cleans a YAML file" do
  #     # Backup original content for comparison
  #     original_content = File.read(sample_yaml_path)
      
  #     ImmosquareYaml.clean(sample_yaml_path)
      
  #     # Check if file content has changed after cleaning
  #     cleaned_content = File.read(sample_yaml_path)
  #     expect(cleaned_content).not_to(eq(original_content))
  #   end
  # end

  # describe ".dump" do
  #   it "creates a YAML file from a Ruby hash" do
  #     ImmosquareYaml.dump(sample_hash, dump_yaml_path)
  #     expect(File.exist?(dump_yaml_path)).to(be(true))
      
  #     dumped_hash = ImmosquareYaml.parse(dump_yaml_path)
  #     expect(dumped_hash).to(eq(sample_hash))
  #   end
  # end
end
