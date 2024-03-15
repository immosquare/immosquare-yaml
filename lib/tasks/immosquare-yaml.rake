namespace :immosquare_yaml do
  ##============================================================##
  ## Function to clean translation files in rails app
  ##============================================================##
  desc "Clean translation files in rails app"
  task :clean => :environment do
    Dir.glob("#{Rails.root}/config/locales/**/*.yml").each do |file|
      ImmosquareYaml.clean(file)
    end
  end
end
