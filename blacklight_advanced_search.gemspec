# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "lib/blacklight_advanced_search/version")

Gem::Specification.new do |s|
  s.name = "blacklight_advanced_search"
  s.version = BlacklightAdvancedSearch::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jonathan Rochkind", "Chris Beer"]
  s.email = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary = "Blacklight Advanced Search plugin"

  s.rubyforge_project = "blacklight"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "blacklight", ">= 5.1", "< 6.0"
  s.add_dependency "parslet"

  s.add_development_dependency "blacklight_marc"
  s.add_development_dependency "rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency 'jettywrapper', ">= 1.4.2"

  # engine_cart 0.3 is out, but can't run tests if we're using it,
  # not sure what we need to change to work with 0.3, possibly cbeer
  # might know, in the meantime locking to 0.2.x. 
  s.add_development_dependency 'engine_cart', "~> 0.2.2"
end
