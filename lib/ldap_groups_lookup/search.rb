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

    # Returns the DN for the given CN attribute
    def lookup_dn(cn)
      service.search(base: tree, filter: Net::LDAP::Filter.equals('cn', cn), attributes: 'dn').first&.dn
    end

    # Returns the mail for a given CN attribute
    def lookup_mail(cn)
      service&.search(base: tree,
                     filter: Net::LDAP::Filter.equals('cn', cn),
                     attributes: 'mail')&.first&.mail&.first.to_s
    end

    # Strips a DN string down to just its CN segment.
    def dn_to_cn(dn)
      dn.match(/CN=(.+?),/)[1]
    end

    # Searches a group and its nested member groups for a member DN
    # @param [Array] groups CNs to search
    # @param [String] dn the DN to search for
    # @param [Array] seen groups that have already been traversed
    # @return [Boolean] true if dn was seen in groups
    def walk_ldap_members(groups, dn, seen = [])
      groups.each do |g|
        members = ldap_members(g)
        return true if members.include? dn
        next if seen.include? g
        seen << g
        member_groups = members.collect do |mg|
          dn_to_cn(mg) if member_allowlist.empty? || member_allowlist.any? do |fil|
            mg.include? fil
          end
        end
        member_groups.compact!
        return true if walk_ldap_members(member_groups, dn, seen)
      end
      return false
    end

    # Gets the entire list of members for a CN.
    # Handles range results.
    # @param [String] cn of the entry to fetch.
    # @param [Integer] start index of range result
    # @return [Array] list of member CNs
    def ldap_members(cn, start=0)
      return [] if service.nil?
      # print "Getting members of #{cn} at index #{start}\n"
      entry = service.search(base: tree,
                             filter: Net::LDAP::Filter.equals('cn', cn),
                             attributes: ["member;range=#{start}-*"]).first
      return [] if entry.nil?

      field_name = entry.attribute_names[1] # Is this always ordered [dn, member]?
      return [] if field_name.nil? # Sometimes member is not present.

      range_end = field_name.to_s.match(/^member;range=\d+-([0-9*]+)$/)[1]
      # print "#{start}-#{range_end}\n"
      members = entry[field_name]#.collect { |mo| mo.split(',').first.split('=')[1] }
      members.concat ldap_members(cn, range_end.to_i+1) unless range_end == '*'
      return members
    end

    # Checks if a user is in a group's membership tree
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
