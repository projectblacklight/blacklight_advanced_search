require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'bundler/setup'
Bundler::GemHelper.install_tasks

APP_ROOT = File.dirname(__FILE__)

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

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
task :ci => ['engine_cart:generate'] do
  require 'solr_wrapper'

  SolrWrapper.wrap(port: '8983') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), "solr", "conf")) do
      Rake::Task['fixtures'].invoke
      Rake::Task['spec'].invoke
    end
  end
end
