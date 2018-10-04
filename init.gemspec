# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "init/version"

Gem::Specification.new do |gem|
  gem.name        = "init"
  gem.version     = Init::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Thomas Sonntag"]
  gem.email       = ["git@sonntagsbox.de"]
  gem.homepage    = ""
  gem.summary     = %q{Job control}
  gem.description = %q{Job control}

  gem.rubyforge_project = "init"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.executables   = [] 
  gem.require_paths = %w(lib)

  gem.add_dependency 'activesupport'
end
