require 'spec_helper'
require 'ldap_groups_lookup/behavior'
require 'pry'

RSpec.describe LDAPGroupsLookup do
  let(:user_class) do
    class User
      def ldap_lookup_key
        'user'
      end
      include LDAPGroupsLookup::Behavior
    end
  end
  let(:user) { user_class.new }

  after do
    LDAPGroupsLookup.reset
  end

  describe '#config' do
    it 'sets the config directly' do
      LDAPGroupsLookup.config = { direct_config: 'works' }
      expect(LDAPGroupsLookup.config).to eq({ direct_config: 'works' })
    end
  end

  context 'with a config file' do
    # Load the example config from fixtures
    let(:config) { YAML.load(ERB.new(File.read(File.join(File.dirname(__dir__), 'fixtures', 'ldap_groups_lookup.yml.example'))).result) }

    before do
      allow(LDAPGroupsLookup).to receive(:config).and_return(config)
    end

    describe '#service' do
      context 'when the config file is missing' do
        before do
          allow(LDAPGroupsLookup).to receive(:config).and_call_original
          expect(File).to receive(:exist?).with(/config\/ldap_groups_lookup\.yml$/)
        end
        it 'should return nil' do
          expect(LDAPGroupsLookup.service).to be_nil
        end
      end
      context 'when disabled in the configuration file' do
        before do
          config[:enabled] = false
        end
        it 'should return nil' do
          expect(LDAPGroupsLookup.service).to be_nil
        end
      end
      context 'when enabled in the configuration file' do
        it 'should be enabled' do
          expect(config[:enabled]).to eq(true)
        end
        context 'when the auth credentials are incorrect' do
          before do
            allow_any_instance_of(Net::LDAP).to receive(:bind).and_return(false)
          end
          it 'should raise an LdapError' do
            expect { LDAPGroupsLookup.service }.to raise_error(Net::LDAP::Error)
          end
        end
        context 'when the auth credentials are correct' do
          before do
            allow_any_instance_of(Net::LDAP).to receive(:bind).and_return(true)
          end
          it 'should return a Net::LDAP instance' do
            expect(LDAPGroupsLookup.service).to be_an_instance_of(Net::LDAP)
          end

          context 'when the :config key is set' do
            let(:config_hash) { { host: 'localhost', port: 636, encryption: { method: :simple_tls, tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS } } }
            before { config[:config] = config_hash }
            it 'uses that config' do
              expect(Net::LDAP).to receive(:new).with(config_hash).and_call_original
              expect(LDAPGroupsLookup.service).to be_an_instance_of(Net::LDAP)
            end
          end
        end
      end
    end

    describe '#ldap_mail' do
      before(:each) do
        entry = Net::LDAP::Entry.new('CN=user,DC=ads,DC=example,DC=net')
        entry['mail'] = ['user@domain.ext']
        allow_any_instance_of(Net::LDAP).to receive(:search).and_return([entry])
        allow_any_instance_of(Net::LDAP).to receive(:bind).and_return(true)
      end
      context 'when subject does not provide ldap_lookup_key method' do
        before(:each) { user.class.send(:remove_method, :ldap_lookup_key) }
        it 'should return ''' do
          expect(user.ldap_mail).to eq('')
        end
      end
      context 'when subject does not provide ldap_lookup_key value' do
        before(:each) { allow(user).to receive(:ldap_lookup_key).and_return(nil) }
        it 'should return ''' do
          expect(user.ldap_mail).to eq('')
        end
      end
      context 'when subject provides ldap_lookup_key' do
        context 'when LDAP is not configured' do
          before(:each) do
            config[:enabled] = false
          end
          it 'should return a blank string' do
            expect(user.ldap_mail).to eq('')
          end
        end
        context 'when LDAP is configured' do
          it 'user should should have a mail attribute in mock LDAP' do
            expect(user.ldap_mail).to eq 'user@domain.ext'
          end
        end
      end
    end

    describe '#ldap_groups' do
      before(:each) do
        entry = Net::LDAP::Entry.new('CN=user,DC=ads,DC=example,DC=net')
        entry['memberof'] = ['CN=Group1,DC=ads,DC=example,DC=net',
                             'CN=Group2,DC=ads,DC=example,DC=net']
        allow_any_instance_of(Net::LDAP).to receive(:search).and_return([entry])
        allow_any_instance_of(Net::LDAP).to receive(:bind).and_return(true)
      end
      context 'when subject does not provide ldap_lookup_key method' do
        before(:each) { user.class.send(:remove_method, :ldap_lookup_key) }
        it 'should return []' do
          expect(user.ldap_groups).to eq([])
        end
      end
      context 'when subject does not provide ldap_lookup_key value' do
        before(:each) { allow(user).to receive(:ldap_lookup_key).and_return(nil) }
        it 'should return []' do
          expect(user.ldap_groups).to eq([])
        end
      end
      context 'when subject provides ldap_lookup_key' do
        context 'when LDAP is not configured' do
          before(:each) do
            config[:enabled] = false
          end
          it 'should return []' do
            expect(user.ldap_groups).to eq([])
          end
        end
        context 'when LDAP is configured' do
          it 'user should belong to Group1 and Group2 in mock LDAP' do
            expect(user.ldap_groups).to eq(%w(Group1 Group2))
          end
        end
      end
    end

    describe '#member_of_ldap_group?' do
      context 'when subject does not provide ldap_lookup_key method' do
        before(:each) { user.class.send(:remove_method, :ldap_lookup_key) }
        it 'should return false' do
          expect(user.member_of_ldap_group?('Test-Group')).to eq(false)
        end
      end
      context 'when subject does not provide ldap_lookup_key value' do
        before(:each) { allow(user).to receive(:ldap_lookup_key).and_return(nil) }
        it 'should return false' do
          expect(user.member_of_ldap_group?('Test-Group')).to eq(false)
        end
      end
      context 'when subject provides ldap_lookup_key' do
        context 'when LDAP is not configured' do
          before(:each) do
            config[:enabled] = false
          end
          it 'should return false' do
            expect(user.member_of_ldap_group?('Test-Group')).to eq(false)
          end
        end
        context 'when LDAP is configured' do
          before(:each) do
            @service = double('ldap_service')
            allow(LDAPGroupsLookup).to receive(:service).and_return(@service)

            allow(LDAPGroupsLookup).to receive(:lookup_dn) do |args|
              Net::LDAP::Entry.new("CN=#{args},DC=ads,DC=example,DC=net").dn
            end

            @other_group = Net::LDAP::Entry.new('CN=Other-Group,OU=Groups,DC=ads,DC=example,DC=net')
            @other_group['member;range=0-*'] = ['CN=otheruser,DC=ads,DC=example,DC=net']

            @nested_group_page_1 = Net::LDAP::Entry.new('CN=Nested-Group,OU=Groups,DC=ads,DC=example,DC=net')
            @nested_group_page_1['member;range=0-0'] = ['CN=otheruser,DC=ads,DC=example,DC=net']

            @nested_group_page_2 = Net::LDAP::Entry.new('CN=Nested-Group,OU=Groups,DC=ads,DC=example,DC=net')
            @nested_group_page_2['member;range=1-*'] = ['CN=user,DC=ads,DC=example,DC=net']

            @top_group = Net::LDAP::Entry.new('CN=Top-Group,OU=Groups,DC=ads,DC=example,DC=net')
            @top_group['member;range=0-*'] = ['CN=Nested-Group,OU=Groups,DC=ads,DC=example,DC=net']

            @no_member_group = Net::LDAP::Entry.new('CN=No-Member-Group,OU=Groups,DC=ads,DC=example,DC=net')
          end
          context 'when searching for a group that does not exist' do
            it 'should return false' do
              expect(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Fake-Group'))).and_return([])
              expect(user.member_of_ldap_group?('Fake-Group')).to eq(false)
            end
          end
          context 'when searching for a group that user is not a member of' do
            it 'should return false' do
              expect(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Other-Group'))).and_return([@other_group])
              expect(user.member_of_ldap_group?('Other-Group')).to eq(false)
            end
          end
          context 'when searching for a group that has no members' do
            it 'should return false' do
              expect(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'No-Member-Group'))).and_return([@no_member_group])
              expect(user.member_of_ldap_group?('No-Member-Group')).to eq(false)
            end
          end
          context 'when searching for a group that user is a direct member of on the second page' do
            it 'should return true' do
              expect(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Nested-Group'),
                                 attributes: ['member;range=0-*'])).and_return([@nested_group_page_1])
              expect(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Nested-Group'),
                                 attributes: ['member;range=1-*'])).and_return([@nested_group_page_2])
              expect(user.member_of_ldap_group?('Nested-Group')).to eq(true)
            end
          end
          context 'when searching for a group that user is a nested member of' do
            before do
              expect(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Top-Group'))).and_return([@top_group])
              allow(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Nested-Group'),
                                 attributes: ['member;range=0-*'])).and_return([@nested_group_page_1])
              allow(@service).to receive(:search).with(
                  hash_including(filter: Net::LDAP::Filter.equals('cn', 'Nested-Group'),
                                 attributes: ['member;range=1-*'])).and_return([@nested_group_page_2])
            end
            context 'when the group is allowlisted' do
              before do
                allow(LDAPGroupsLookup).to receive(:member_allowlist).and_return(['OU=Groups'])
              end
              it 'should return true' do
                expect(user.member_of_ldap_group?('Top-Group')).to eq(true)
              end
            end
            context 'when the allowlist is empty' do
              before do
                allow(LDAPGroupsLookup).to receive(:member_allowlist).and_return([])
              end
              it 'should return true (allowlisting is disabled)' do
                expect(user.member_of_ldap_group?('Top-Group')).to eq(true)
              end
            end
            context 'when the group is not allowlisted' do
              before do
                allow(LDAPGroupsLookup).to receive(:member_allowlist).and_return(['OU=Not-A-Match'])
              end
              it 'should return false' do
                expect(user.member_of_ldap_group?('Top-Group')).to eq(false)
              end
            end
          end
        end
      end
    end
  end
end