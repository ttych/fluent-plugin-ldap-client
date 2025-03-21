# frozen_string_literal: true

#
# Copyright 2025- Thomas Tych
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fluent/plugin/filter'

# require 'lru_redux'

require_relative 'ldap_client/ldap_client'
require_relative 'ldap_client/no_cache'
require_relative 'ldap_client/cache_ttl'

module Fluent
  module Plugin
    class LdapEnrichFilter < Fluent::Plugin::Filter
      NAME = 'ldap_enrich'
      Fluent::Plugin.register_filter(NAME, self)

      DEFAULT_LDAP_HOST = 'localhost'
      DEFAULT_LDAP_PORT = 389
      DEFAULT_LDAP_ENCRYPTION = false
      DEFAULT_LDAP_BASE_DN = ''
      DEFAULT_LDAP_USERNAME = nil
      DEFAULT_LDAP_PASSWORD = nil

      desc 'ldap host'
      config_param :ldap_host, :string, default: DEFAULT_LDAP_HOST
      desc 'ldap port'
      config_param :ldap_port, :integer, default: DEFAULT_LDAP_PORT
      desc 'ldap encryption'
      config_param :ldap_encryption, :bool, default: DEFAULT_LDAP_ENCRYPTION
      desc 'ldap base DN'
      config_param :ldap_base_dn, :string, default: DEFAULT_LDAP_BASE_DN
      desc 'ldap username'
      config_param :ldap_username, :string, default: DEFAULT_LDAP_USERNAME
      desc 'ldap password'
      config_param :ldap_password, :string, default: DEFAULT_LDAP_PASSWORD, secret: true

      desc 'CA cert'
      config_param :ca_cert, :string, default: nil

      DEFAULT_LDAP_ATTRIBUTES = {}.freeze

      desc 'ldap query'
      config_param :ldap_query, :string, default: nil
      desc 'ldap attributes to inject in record'
      config_param :ldap_attributes, :hash, default: DEFAULT_LDAP_ATTRIBUTES, symbolize_keys: false, value_type: :string

      DEFAULT_CACHE_ENABLE = true
      DEFAULT_CACHE_SIZE = 1000
      DEFAULT_CACHE_TTL_POSITIVE = 24 * 3600
      DEFAULT_CACHE_TTL_NEGATIVE = 3600

      desc 'enable cache'
      config_param :cache_enable, :bool, default: DEFAULT_CACHE_ENABLE
      desc 'cache size'
      config_param :cache_size, :integer, default: DEFAULT_CACHE_SIZE
      desc 'cache ttl positive'
      config_param :cache_ttl_positive, :integer, default: DEFAULT_CACHE_TTL_POSITIVE
      desc 'cache ttl negative'
      config_param :cache_ttl_negative, :integer, default: DEFAULT_CACHE_TTL_NEGATIVE

      def configure(conf)
        super

        raise Fluent::ConfigError, 'ldap_query should be defined' if !ldap_query || ldap_query.empty?
        raise Fluent::ConfigError, 'ldap_attributes should be defined' if !ldap_attributes || ldap_attributes.empty?

        true
      end

      def start
        super

        @ldap_client = Fluent::Plugin::LdapClient::LdapClient.new(
          host: ldap_host,
          port: ldap_port,
          base_dn: ldap_base_dn,
          username: ldap_username,
          password: ldap_password,
          encryption: ldap_encryption,
          ca_cert: ca_cert,
          log: log
        )

        @cache = if cache_enable
                   Fluent::Plugin::LdapClient::CacheTTL.new(
                     size: cache_size,
                     ttl_positive: cache_ttl_positive,
                     ttl_negative: cache_ttl_negative
                   )
                 else
                   Fluent::Plugin::LdapClient::NoCache.new
                 end
      end

      def shutdown
        @ldap_client.close

        super
      end

      def filter(_tag, _time, record)
        return record if !ldap_query || ldap_query.empty?
        return record if !ldap_attributes || ldap_attributes.empty?

        query_string = interpolate_ldap_query(record)
        return record unless query_string

        ldap_result = @cache.get(query_string) do |ldap_query_string|
          @ldap_client.search_query(ldap_query_string)
        end

        if ldap_result
          ldap_attributes.each do |key, record_key|
            record[record_key] = (ldap_result[key.to_sym] || ldap_result[key])&.join(', ')
          end
        end
        record
      end

      def interpolate_ldap_query(record)
        ldap_query % record.transform_keys(&:to_sym)
      rescue StandardError => e
        log.warn("#{NAME}: while interpolating ldap_query \"#{ldap_query}\", #{e.message}")
        nil
      end
    end
  end
end
