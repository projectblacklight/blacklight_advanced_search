# frozen_string_literal: true

require 'bundler/setup'
Bundler::GemHelper.install_tasks

require 'rdoc/task'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'net/http'

# Run Solr with docker compose when it's available, otherwise with solr_wrapper.
def with_solr(&block)
  if system('docker compose version', out: File::NULL, err: File::NULL)
    with_docker_solr(&block)
  else
    with_solr_wrapper(&block)
  end
end

def with_docker_solr
  puts 'Starting Solr'
  system('docker compose up -d solr', exception: true)
  wait_for_solr
  yield
ensure
  puts 'Stopping Solr'
  system('docker compose stop solr')
end

def with_solr_wrapper(&block)
  require 'solr_wrapper'

  SolrWrapper.wrap(port: '8983') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(__dir__), "solr", "conf"), &block)
  end
end

# `docker compose up -d` returns before Solr has created the core.
def wait_for_solr(timeout: 60)
  ping = URI("http://127.0.0.1:#{ENV.fetch('SOLR_PORT', 8983)}/solr/blacklight-core/admin/ping")
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

  until solr_ping?(ping)
    raise "Solr did not respond at #{ping} within #{timeout} seconds" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

    sleep 1
  end
end

def solr_ping?(uri)
  Net::HTTP.get_response(uri).is_a?(Net::HTTPSuccess)
rescue StandardError
  false
end

task :default => %i[rubocop ci]

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
task :ci => ['engine_cart:generate'] do
  with_solr do
    Rake::Task['fixtures'].invoke
    Rake::Task['spec'].invoke
  end
end

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop-rspec'
  task.fail_on_error = true
end
