blacklight_plugin_dir = "#{File.dirname(__FILE__)}/../.."

gem 'test-unit', '1.2.3' if RUBY_VERSION.to_f >= 1.9
rspec_gem_dir = nil
Dir["#{blacklight_plugin_dir}/vendor/gems/*"].each do |subdir|
  rspec_gem_dir = subdir if subdir.gsub("#{blacklight_plugin_dir}/vendor/gems/","") =~ /^(\w+-)?rspec-(\d+)/ && File.exist?("#{subdir}/lib/spec/rake/spectask.rb")
end
rspec_plugin_dir = File.expand_path(File.dirname(__FILE__) + '/../../vendor/plugins/rspec')

if rspec_gem_dir && (test ?d, rspec_plugin_dir)
  raise "\n#{'*'*50}\nYou have rspec installed in both vendor/gems and vendor/plugins\nPlease pick one and dispose of the other.\n#{'*'*50}\n\n"
end

if rspec_gem_dir
  $LOAD_PATH.unshift("#{rspec_gem_dir}/lib")
elsif File.exist?(rspec_plugin_dir)
  $LOAD_PATH.unshift("#{rspec_plugin_dir}/lib")
end

# Don't load rspec if running "rake gems:*"
unless ARGV.any? {|a| a =~ /^gems/}

  begin
    require 'spec/rake/spectask'
  rescue MissingSourceFile
    module Spec
      module Rake
        class SpecTask
          def initialize(name)
            task name do
              # if rspec-rails is a configured gem, this will output helpful material and exit ...
              require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")

              # ... otherwise, do this:
              raise <<-MSG

  #{"*" * 80}
  *  You are trying to run an rspec rake task defined in
  *  #{__FILE__},
  *  but rspec can not be found in vendor/gems, vendor/plugins or system gems.
  #{"*" * 80}
  MSG
            end
          end
        end
      end
    end
  end
  
  namespace :spec do
    Spec::Rake::SpecTask.new(:rspec) do |t|
      t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
      t.spec_files = FileList['spec/**/*_spec.rb']
      t.rcov = true
      t.rcov_opts = lambda do
        IO.readlines("#{RAILS_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
      end
    end
    desc 'Run rspec tests'
    task :all do |t|
      Rake::Task["spec:rspec"].invoke
    end
  end
end