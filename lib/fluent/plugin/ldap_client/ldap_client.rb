# frozen_string_literal: true

require 'net/ldap'

module Fluent
  module Plugin
    module LdapClient
      class LdapClient
        CONNECT_TIMEOUT = 10

        attr_reader :host, :port, :base_dn, :username, :password, :encryption, :ca_cert, :connect_timeout, :log

        def initialize(host:, port:, base_dn:, username:, password:, encryption: false, ca_cert: nil,
                       connect_timeout: CONNECT_TIMEOUT, log: nil)
          @host = host
          @port = port
          @encryption = encryption
          @base_dn = base_dn
          @username = username
          @password = password

          @ca_cert = ca_cert
          @connect_timeout = connect_timeout

          @log = log
        end

        def ldap
          @ldap ||= Net::LDAP.new(
            host: host,
            port: port,
            base: base_dn,
            auth: ldap_auth,
            encryption: ldap_encryption,
            connect_timeout: connect_timeout
          )
          raise "LDAP Client authentication failed: #{@ldap.get_operation_result.message}" unless @ldap.bind

          @ldap
        rescue StandardError => e
          log&.error "LDAP Client error: #{e.message}"
          @dap = nil
        end

        def ldap_auth
          return unless username && password

          { method: :simple,
            username: username,
            password: password }
        end

        def ldap_encryption
          return unless encryption

          { method: :simple_tls,
            tls_options: { ca_file: ca_cert } }
        end

        def search_query(query)
          return nil unless ldap && query

          filter = Net::LDAP::Filter.construct(query)
          search_filter(filter)
        rescue StandardError => e
          log&.warn "LDAP Client error: query \"#{query}\" failed: #{e.message}"
          nil
        end

        def search_filter(filter)
          result = ldap.search(base: base_dn, filter: filter)
          log&.debug "LDAP Client: No LDAP results for filter \"#{filter}\"" if result.nil? || result.empty?

          result&.first&.to_h
        rescue StandardError => e
          log&.warn "LDAP Client error: query failed: #{e.message}"
          nil
        end

        def close
          @ldap = nil
        end
      end
    end
  end
end
