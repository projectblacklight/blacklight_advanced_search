#RAILS_ROOT = "#{File.dirname(__FILE__)}/.."

Dir[Pathname.new(File.expand_path("../support/**/*.rb", __FILE__))].each {|f| require f}
require 'lib/blacklight_advanced_search'

RSpec.configure do |config|

end

