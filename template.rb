
plugin_root = "vendor/plugins/blacklight_advanced_search"

if yes?("install example Blacklight Advanced Search config file?")

    
  advanced_search_config = "config/initializers/blacklight_advanced_search_config.rb"
  
  if (!File.exists? advanced_search_config) || yes?("Over-write existing config/initializers/blacklight_advanced_search_config.rb ?")
    puts "\n* Copying sample Blacklight Advanced Search config to your config/initializers directory..."

    
    
    FileUtils.cp( File.join(plugin_root, advanced_search_config), advanced_search_config )
  end

end

if yes?("Install all application gem dependencies using 'sudo', including new ones from this plugin?")
  rake "gems:install", :sudo=>true
end
