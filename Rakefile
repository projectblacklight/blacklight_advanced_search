# frozen_string_literal: true

require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rdoc/task'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'engine_cart/rake_task'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

desc "Load fixtures"
task :fixtures => ['engine_cart:generate'] do
  within_test_app do
    ENV['RAILS_ENV'] ||= 'test'
    system "rake blacklight:index:seed"
    abort "Error running fixtures" unless $?.success?
  end
end

desc "Execute Continuous Integration build"
task :ci => ['rubocop', 'engine_cart:generate'] do
  require 'solr_wrapper'

  SolrWrapper.wrap(port: '8983') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(__dir__), "solr", "conf")) do
      Rake::Task['fixtures'].invoke
      Rake::Task['spec'].invoke
    end
  end
end

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end
