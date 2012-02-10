# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "webyast-administrator"
  s.version = "0.1"
  s.authors = ["WebYaST team"]
  s.summary = "Webyast module for configuring administrator settings"
  s.email = "yast-devel@opensuse.org"
  s.licenses = ['GPL-2.0']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
