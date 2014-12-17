source 'http://rubygems.org'

gemspec

file = File.expand_path("Gemfile", ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path("../spec/internal", __FILE__))
if File.exists?(file)
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
else
  gem 'rails', ENV['RAILS_VERSION']
  
  # explicitly include sass-rails to get compatible sprocket dependencies
  if ENV['RAILS_VERSION'] and ENV['RAILS_VERSION'] =~ /^4.2/
    gem 'sass-rails', ">= 5.0.0.beta1"
    gem 'responders', "~> 2.0"
  else
    gem 'sass-rails', "< 5.0"
    gem 'coffee-rails', "~> 4.0.0"
  end
end