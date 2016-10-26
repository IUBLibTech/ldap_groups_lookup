require 'spec_helper'
require 'ldap_groups_lookup/behavior'

RSpec.describe LDAPGroupsLookup do
  let(:user_class) do
    class User
      def ldap_lookup_key
        'return username here'
      end
      include LDAPGroupsLookup::Behavior
    end
  end
  let(:user) { user_class.new }
  describe '#ldap_groups' do
    before(:each) do
      entry = Net::LDAP::Entry.new('cn=user,dc=ads,dc=example,dc=edu')
      entry['memberof'] = ['CN=Group1,DC=ads,DC=example,DC=edu',
                           'CN=Group2,DC=ads,DC=example,DC=edu']
      allow_any_instance_of(Net::LDAP).to receive(:search).and_return([entry])
      allow(LDAPGroupsLookup).to receive(:config)
        .and_return(YAML.load(ERB.new(File.read(File.join(File.dirname(__dir__), 'fixtures', 'ldap_groups_lookup.yml.example'))).result))
    end
    context 'when subject does not provide ldap_lookup_key' do
      before(:each) { user.class.send(:remove_method, :ldap_lookup_key) }
      it 'should return []' do
        expect(user.send(:ldap_groups)).to eq([])
      end
    end
    context 'when subject provides ldap_lookup_key' do
      context 'when LDAP is not configured' do
        before(:each) do
          allow(LDAPGroupsLookup).to receive(:service).and_return(nil)
        end
        it 'should return []' do
          expect(user.send(:ldap_groups)).to eq([])
        end
      end
      context 'when LDAP is configured' do
        specify 'user should belong to Group1 and Group2 in mock LDAP' do
          expect(user.send(:ldap_groups)).to eq(%w(Group1 Group2))
        end
      end
    end
  end
end
