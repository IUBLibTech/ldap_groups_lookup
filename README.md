# IU LDAP Groups Lookup

Adds an LDAPGroupsLookup that can be included in a a class to provide an #ldap_groups instance method:

```
class User
  attr_accessor :ldap_lookup_key
  include LDAPGroupsLookup::Behavior
end

u = User.new
u.ldap_lookup_key = 'some_username'
u.ldap_groups
u.member_of_ldap_group?(['Some-Group'])
```

The LDAP search will be run by the value of #ldap_lookup_key, so your instance object must provide that through some means:

```
class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true
  alias_attribute :ldap_lookup_key, :username
  include LDAPGroupsLookup::Behavior
end

u = User.find_by(username: 'some_username')
u.ldap_groups
u.member_of_ldap_group?(['Some-Group'])
```
