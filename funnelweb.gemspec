# -*- encoding: utf-8 -*-

# This is Funnelweb, a web-spider framework based on Anemone by Chris Kite.

$:.push File.expand_path("../lib", __FILE__)
require "funnelweb/version"

Gem::Specification.new do |s|
  s.name        = "funnelweb"
  s.version     = Funnelweb::VERSION
  s.authors     = ["James K Nelson"]
  s.email       = ["james@numbat.com.au"]
  s.homepage    = "http://funnelweb.rubyforge.org"
  s.summary     = "Funnelweb web-spider framework, based on Anemone by Chris Kite"

  s.rubyforge_project = "funnelweb"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.has_rdoc = true
  s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'Anemone'
  s.extra_rdoc_files = ["README.rdoc"]
  
  s.add_dependency("rake", ">= 0.9.2.2")
  s.add_dependency("nokogiri", ">= 1.3.0")
  s.add_dependency("robots", ">= 0.7.2")
  s.add_dependency("active_support", ">= 3.0.0")
  s.add_dependency("resque", ">= 1.19.0")
  s.add_dependency("resque-scheduler", ">= 1.9.9")
  s.add_dependency("colorize", ">= 0.5.8")
end