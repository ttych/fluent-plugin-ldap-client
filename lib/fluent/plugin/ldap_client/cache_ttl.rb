# frozen_string_literal: true

module Fluent
  module Plugin
    module LdapClient
      class CacheTTL
        CACHE_SIZE = 1000
        TTL_POSITIVE = 14 * 3600
        TTL_NEGATIVE = 3600

        attr_reader :size, :ttl_positive, :ttl_negative

        def initialize(size: CACHE_SIZE, ttl_positive: TTL_POSITIVE, ttl_negative: TTL_NEGATIVE)
          @size = size
          @ttl_positive = ttl_positive
          @ttl_negative = ttl_negative

          @cache = {}
          @access_order = []
        end

        def get(key)
          cleanup_expired_entries

          if @cache.key?(key) && !expired?(@cache[key])
            refresh_access_order(key)
            return @cache[key][:value]
          end

          result = yield key
          store(key, result)
          result
        end

        private

        def store(key, value)
          evict_if_needed

          ttl = value.nil? ? @ttl_negative : @ttl_positive
          @cache[key] = { value: value, expires_at: Time.now + ttl }
          refresh_access_order(key)
        end

        def expired?(entry)
          Time.now > entry[:expires_at]
        end

        def cleanup_expired_entries
          @cache.each_key do |key|
            if expired?(@cache[key])
              @cache.delete(key)
              @access_order.delete(key)
            end
          end
        end

        def evict_if_needed
          return unless @cache.size > size

          lru_key = @access_order.shift
          @cache.delete(lru_key)
        end

        def refresh_access_order(key)
          @access_order.delete(key)
          @access_order << key
        end
      end
    end
  end
end
