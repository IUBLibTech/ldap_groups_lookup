require 'net/ldap'

# Adds #ldap_groups instance method
# Object must provide #ldap_lookup_key to use for LDAP group search
module LDAPGroupsLookup
  class InitializationError < RuntimeError; end

  autoload :Configuration, 'ldap_groups_lookup/configuration'
  autoload :Search, 'ldap_groups_lookup/search'
  autoload :Behavior, 'ldap_groups_lookup/behavior'

  class << self
    include LDAPGroupsLookup::Configuration
    include LDAPGroupsLookup::Search
  end
end
