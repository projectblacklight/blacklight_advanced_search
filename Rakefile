require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'bundler/setup'
Bundler::GemHelper.install_tasks

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.3.zip"
APP_ROOT = File.dirname(__FILE__)

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

require 'jettywrapper'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

  desc "Load fixtures"
  task :fixtures => ['engine_cart:generate'] do
    within_test_app do
      ENV['RAILS_ENV'] ||= 'test'
      system "rake blacklight:index:seed"
      abort "Error running fixtures" unless $?.success?
    end
  end

desc "Execute Continuous Integration build"
task :ci => ['jetty:clean', 'engine_cart:generate'] do

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
