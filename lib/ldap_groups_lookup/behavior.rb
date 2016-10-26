# Adds #ldap_groups instance method
# Object must provide #ldap_lookup_key to use for LDAP group search
module LDAPGroupsLookup
  module Behavior
    require 'ldap_groups_lookup'

    # Searches object's nested LDAP groups by value of ldap_lookup_key
    # @return [Array] all of the object's LDAP groups, sorted
    def ldap_groups
      return [] unless respond_to? :ldap_lookup_key
      LDAPGroupsLookup.walk_ldap_groups(
          LDAPGroupsLookup.ldap_member_of(ldap_lookup_key)
      ).sort
    end
  end
end
