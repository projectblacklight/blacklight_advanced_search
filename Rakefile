require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'bundler/setup'
Bundler::GemHelper.install_tasks

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.0.0.zip"
APP_ROOT = File.expand_path("..", __FILE__)

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

require 'blacklight'
import File.join(Blacklight.root, 'lib', 'railties', 'solr_marc.rake')

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

  desc "Load fixtures"
  task :fixtures => ['engine_cart:generate'] do
    within_test_app do
      system "rake solr:marc:index_test_data RAILS_ENV=test"
      abort "Error running fixtures" unless $?.success?
    end
  end

desc "Execute Continuous Integration build"
task :ci => ['engine_cart:generate'] do

  require 'jettywrapper'
  jetty_params = {
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/jetty'),
    :quiet => false,
    :jetty_port => 8888,
    :solr_home => File.expand_path(File.dirname(__FILE__) + '/jetty/solr'),
    :startup_wait => 30
  }

  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['fixtures'].invoke
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end
