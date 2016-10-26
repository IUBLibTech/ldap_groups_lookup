module LDAPGroupsLookup
  module Search
    # Searches (without recursion) LDAP groups
    # @param [String] cn the group or user to search by
    # @return [Array] LDAP groups for cn, one level deep, unsorted
    def ldap_member_of(cn)
      return [] if service.nil?
      entry = service.search(base: tree,
                                filter: Net::LDAP::Filter.equals('cn', cn),
                                attributes: ['memberof']).first
      if entry.nil?
        []
      else
        entry['memberof'].collect { |mo| mo.split(',').first.split('=')[1] }
      end
    end

    # Searches (recursively) LDAP group membership tree
    # @param [Array] groups to search group membership of
    # @param [Array] seen the accumulated list of group membership, defaults to []
    # @return [Array] results of searching group membership tree
    def walk_ldap_groups(groups, seen = [])
      groups.each do |g|
        next if seen.include? g
        seen << g
        walk_ldap_groups(ldap_member_of(g), seen)
      end
      seen
    end

    # Checks if a user is a direct member of a group
    # @param [String] username to search for
    # @param [String] groupname to search within
    # @return [Boolean]
    def belongs_to_ldap_group?(username, groupname)
      return false if service.nil?
      group_filter = Net::LDAP::Filter.equals('cn', groupname)
      member_filter = Net::LDAP::Filter.equals('member', "cn=#{username},#{account_tree}")
      entry = service.search(base: tree,
                             filter: group_filter & member_filter,
                             attributes: ['cn'])
      entry.count > 0
    end

    # Lists all groups that a user belongs to.
    # Warning: Utilizes server-side recursive search but may be slower than walking the tree client-side.
    # @param [string] username the user to search by
    def all_ldap_groups(username)
      return [] if service.nil?
      results = service.search(base: group_tree,
                   filter: Net::LDAP::Filter.eq('objectcategory', 'group') &
                       Net::LDAP::Filter.ex('member:1.2.840.113556.1.4.1941',
                                            "CN=#{Net::LDAP::Filter.escape(username)},#{account_tree}"),
                   attributes: ['cn'])
      if results.nil?
        []
      else
        results.collect do |entry|
          entry[:cn].first
        end
      end
    end
  end
end
