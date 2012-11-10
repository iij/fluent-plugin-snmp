# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-snmp"
  gem.version       = "0.0.1"
  gem.authors       = ["Hiroshi Sugimoto"]
  gem.email         = ["h-sugimoto@iij.ad.jp"]
  gem.description   = %q{Input plugin to walk snmp}
  gem.summary       = %q{Input plugin to walk snmp}

  gem.files         = `git ls-files`.split($\)                                    
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "fluentd"
  gem.add_development_dependency "snmp"
  gem.add_development_dependency "polling"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "snmp"
  gem.add_runtime_dependency "polling"
end
