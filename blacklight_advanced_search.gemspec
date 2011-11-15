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


  s.add_dependency "rails", "~> 3.0"
  s.add_dependency "blacklight", "~> 3.2"
  s.add_dependency "parslet"
end
