# IU LDAP Groups Lookup

## Usage

Adds an LDAPGroupsLookup that can be included in a a class to provide an #ldap_groups instance method:

```ruby
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

```ruby
class User < ActiveRecord::Base
  validates :username, presence: true, uniqueness: true
  alias_attribute :ldap_lookup_key, :username
  include LDAPGroupsLookup::Behavior
end

u = User.find_by(username: 'some_username')
u.ldap_groups
u.member_of_ldap_group?(['Some-Group'])
```

## Configuration

### Initializer
Create an initializer `config/initializers/ldap_groups_lookup.rb` that looks like:
```ruby
LDAPGroupsLookup.config = {
  enabled: true,
  config: { host: 'ads.example.net',
            port: 636,
            encryption: {
              method: :simple_tls,
              tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS,
            },
            auth: {
              method: :simple,
              username: "cn=example",
              password: 'changeme',
            }
  },
  tree: 'dc=ads,dc=example,dc=net',
  account_ou: 'ou=Accounts',
  group_ou: 'ou=Groups',
  member_whitelist: ['OU=Groups']
}
```

### YAML
Alternatively, create a file `config/ldap_groups_lookup.yml` that looks like:

```yaml
:enabled: true
:host: ads.example.net
:port: 389
:auth:
  :method: :simple
  :username: example
  :password: changeme
:tree: dc=ads,dc=example,dc=net
:account_ou: ou=Accounts
:group_ou: ou=Groups
:member_whitelist:
  - OU=Groups
```
Note: The yaml style does not allow for easy configuration of some properties like tls_options or other auth methods.