require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end


desc "Execute Continuous Integration build"
task :ci do
  unless ENV['environment'] == 'test'
    exec("rake ci environment=test") 
  end

  require 'jettywrapper'
  jetty_params = {
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/jetty'),
    :quiet => false,
    :jetty_port => 8983,
    :solr_home => File.expand_path(File.dirname(__FILE__) + '/jetty/solr'),
    :startup_wait => 30
  }

  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end
