unless File.exists? 'vendor/plugins/blacklight'
  puts "****ERROR: The Blacklight Advanced Search Plugin requires that Blacklight be installed first"
  exit 0 
end
puts "\n* Blacklight Advanced Search Rails Template \n\n"

plugin_dirname = 'blacklight_advanced_search'

tag = nil


# cp the blacklight_advanced_search initializer file from the plugin up to the new app
puts "\n* Copying the Blacklight Advanced Search config to your config/initializers directory..."
advanced_search_config = "config/initializers/blacklight_advanced_search_config.rb"
unless File.exists? advanced_search_config
  FileUtils.cp "vendor/plugins/#{plugin_dirname}/config/initializers/blacklight_advanced_search_config.rb", advanced_search_config
else
  puts "** There appears to be an existing blacklight_advanced_search configuration file.  Skipping....."
end

if yes?("Would you like to install the gem dependecies now?")
  if yes? "Do you want to install gems using sudo?"
    user = run("whoami").chomp
    run "sudo gem install rubytree -v '=0.5.2' && sudo chown -R #{user} public/plugin_assets"
  else
    run "gem install rubytree -v '=0.5.2'"
  end
end

puts "\n* Blacklight Advanced Search Successfully Installed..."
puts "\n* You should now modify your app level blacklight_advanced_search_config.rb file located in your config/initializers directory to match your solr configuration"