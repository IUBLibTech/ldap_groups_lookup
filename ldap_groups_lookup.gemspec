# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldap_groups_lookup/version'

Gem::Specification.new do |gem|
  gem.name          = 'ldap_groups_lookup'
  gem.version       = LDAPGroupsLookup::VERSION
  gem.authors       = ['Adam Ploshay', 'Daniel Pierce', 'Avalon Media System']
  gem.email         = ['aploshay@iu.edu', 'dlpierce@iu.edu']
  gem.description   = 'Provides easy access to the list of LDAP groups a username is a member of.'
  gem.summary       = 'Provides easy access to the list of LDAP groups a username is a member of.'
  gem.homepage      = 'http://github.com/IUBLibTech/ldap_groups_lookup'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.required_ruby_version = '2.3.1'

  gem.add_dependency 'net-ldap'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
