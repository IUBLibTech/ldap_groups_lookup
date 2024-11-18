require 'yaml'
require 'erb'

# Provides access to the configuration YAML file.
module LDAPGroupsLookup
  module Configuration

    # Attempts to create a connection to LDAP and returns a cached Net::LDAP instance if successful.
    def service
      return nil if config[:enabled] == false
      if @ldap_service.nil?
        @ldap_service = Net::LDAP.new(host: config[:host], port: config[:port] || Net::LDAP::DefaultPort, auth: config[:auth])
        raise Net::LDAP::Error unless @ldap_service.bind
      end
      @ldap_service
    end

    # Loads LDAP host and authentication configuration
    def config
      if @config.nil?
        if defined? Rails
          configure(Rails.root.join('config', 'ldap_groups_lookup.yml').to_s)
        else
          configure(File.join(__dir__, '..', '..', 'config', 'ldap_groups_lookup.yml').to_s)
        end
      end
      @config
    end

    # Clears internal cached objects.
    def reset
      @ldap_service = nil
      @config = nil
    end

    def group_tree
      "#{config[:group_ou]},#{tree}"
    end

    def account_tree
      "#{config[:account_ou]},#{tree}"
    end

    def tree
      config[:tree]
    end

    def member_whitelist
      config[:member_whitelist].to_a
    end

    private

    def configure(value)
      if value.nil? || value.is_a?(Hash)
        @config = value
      elsif value.is_a?(String)
        if File.exist?(value)
          @config = YAML.load(ERB.new(File.read(value)).result)
        else
          @config = { enabled: false }
        end
      else
        raise InitializationError, "Unrecognized configuration: #{value.inspect}"
      end
    end
  end
end
