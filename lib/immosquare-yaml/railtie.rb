module ImmosquareYaml
  class Railtie < Rails::Railtie

    rake_tasks do
      load "tasks/immosquare-yaml.rake"
    end

  end
end