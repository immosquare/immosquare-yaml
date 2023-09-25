namespace :immosquare_yaml do
  
  ##============================================================##
  ## Function to translate translation files in rails app
  ##============================================================##
  desc "Translate translation files in rails app"
  task :translate => :environment do
    source_locale  = "fr"
    locales        = I18n.available_locales.map(&:to_s).reject {|l| l == source_locale }
    Dir.glob("#{Rails.root}/config/locales/**/*#{source_locale}.yml").each do |file|
      locales.each do |locale|
        ImmosquareYaml::Translate.translate(file, locale) 
      end
    end
  end

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