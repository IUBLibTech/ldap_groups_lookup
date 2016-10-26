require 'yaml'

# Provides access to the configuration YAML file.
module LDAPGroupsLookup
  module Configuration
    def group_tree
      "#{config[:group_ou]},#{tree}"
    end

    def account_tree
      "#{config[:account_ou]},#{tree}"
    end

    def tree
      config[:tree]
    end

    def service
      if @ldap_service.nil?
        @ldap_service = Net::LDAP.new(host: config[:host], auth: config[:auth])
      end
      @ldap_service
    end

    def config
      if @config.nil?
        if defined? Rails
          configure(Rails.root.join('config', 'ldap_groups_lookup.yml').to_s)
        else
          configure(__dir__.join('config', 'ldap_groups_lookup.yml').to_s)
        end

      end
      @config
    end

    def configure(value)
      if value.nil? || value.is_a?(Hash)
        @config = value
      elsif value.is_a?(String)
        @config = YAML.load(ERB.new(File.read(value)).result)
      else
        raise InitializationError, "Unrecognized configuration: #{value.inspect}"
      end
    end
  end
end
