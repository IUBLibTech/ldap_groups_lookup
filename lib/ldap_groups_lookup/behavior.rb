# Adds #ldap_groups instance method
# Object must provide #ldap_lookup_key to use for LDAP group search
module LDAPGroupsLookup
  module Behavior
    require 'ldap_groups_lookup'

    # @return String object's mail attribute
    def ldap_mail
      return '' unless respond_to?(:ldap_lookup_key) && ldap_lookup_key.to_s.size.positive?
      LDAPGroupsLookup.lookup_mail(ldap_lookup_key)
    end

    # Searches object's nested LDAP groups by value of ldap_lookup_key
    # @return [Array] all of the object's LDAP groups, sorted
    def ldap_groups
      return [] unless respond_to?(:ldap_lookup_key) && ldap_lookup_key.to_s.size.positive?
      LDAPGroupsLookup.walk_ldap_groups(
          LDAPGroupsLookup.ldap_member_of(ldap_lookup_key)
      ).sort
    end

    # Checks if a user is in a group's membership tree
    # @param [Array] groups is a list of group CN strings to search within
    # @return [Boolean]
    def member_of_ldap_group?(groups)
      return false unless respond_to?(:ldap_lookup_key) && ldap_lookup_key.to_s.size.positive?
      return false if LDAPGroupsLookup.service.nil?
      groups = [groups] if groups.is_a? String
      dn = LDAPGroupsLookup.lookup_dn(ldap_lookup_key)
      return LDAPGroupsLookup.walk_ldap_members(groups, dn)
    end
  end
end
