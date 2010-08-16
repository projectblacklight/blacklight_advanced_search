
plugin_root = "vendor/plugins/blacklight_advanced_search"

if yes?("Install optional example Blacklight Advanced Search config file?")

    
  advanced_search_config = "config/initializers/blacklight_advanced_search_config.rb"
  
  if (!File.exists? advanced_search_config) || yes?("Over-write existing config/initializers/blacklight_advanced_search_config.rb ?")
        
    FileUtils.cp( File.join(plugin_root, advanced_search_config), advanced_search_config )
    puts "\n* Copied example Blacklight Advanced Search config to config/initializers/blacklight_advanced_search.rb"
  end

end

if yes?("Install all application gem dependencies using 'sudo', including new ones from this plugin?")
  rake "gems:install", :sudo=>true
end

if yes?("Install local search form with advanced link?")
  destination = "app/views/catalog/_search_form.html.erb"
  if (! File.exists?(destination) or yes?("Over-write existing #{destination}?"))
    FileUtils.cp( File.join(plugin_root, "example/_search_form.html.erb"), destination )
    puts "\n* Copied search form to #{destination}"
  end
end


