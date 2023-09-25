namespace :immosquare_yaml do
  
  ##============================================================##
  ## Function to translate translation files in rails app
  ## rake immosquare_yaml:translate LOCALE=fr
  ##============================================================##
  desc "Translate translation files in rails app"
  task :translate => :environment do
    begin
      source_locale = ENV.fetch("LOCALE", nil) || "fr"
      raise("Please provide a valid locale") if !I18n.available_locales.map(&:to_s).include?(source_locale)

      locales = I18n.available_locales.map(&:to_s).reject {|l| l == source_locale }
      Dir.glob("#{Rails.root}/config/locales/**/*#{source_locale}.yml").each do |file|
        locales.each do |locale|
          ImmosquareYaml::Translate.translate(file, locale) 
        end
      end
    rescue StandardError => e
      puts(e.message)
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