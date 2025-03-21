# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/filter_ldap_enrich'

class LdapEnrichFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup

    @conf = %(
      ldap_query test_query
      ldap_attributes test_key:test_key
    )

    @ldap_client_mock = mock('Fluent::Plugin::LdapClient::LdapClient')
  end

  sub_test_case 'configuration' do
    test 'default configuration' do
      driver = create_driver(@conf)
      input = driver.instance

      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_LDAP_HOST, input.ldap_host
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_LDAP_PORT, input.ldap_port
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_LDAP_ENCRYPTION, input.ldap_encryption
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_LDAP_BASE_DN, input.ldap_base_dn
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_LDAP_USERNAME, input.ldap_username
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_LDAP_PASSWORD, input.ldap_password
      assert_equal nil, input.ca_cert
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_CACHE_ENABLE, input.cache_enable
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_CACHE_SIZE, input.cache_size
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_CACHE_TTL_POSITIVE, input.cache_ttl_positive
      assert_equal Fluent::Plugin::LdapEnrichFilter::DEFAULT_CACHE_TTL_NEGATIVE, input.cache_ttl_negative
    end

    test 'can inject ldap_query' do
      conf = %(
        ldap_query test_ldap_query
        ldap_attributes test:test
      )
      driver = create_driver(conf)
      input = driver.instance

      assert_equal 'test_ldap_query', input.ldap_query
    end

    test 'ldap_query should not be empty' do
      conf = %(
        ldap_attributes test:test
      )

      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end

    test 'can inject ldap_attributes' do
      conf = %(
        ldap_query test_ldap_query
        ldap_attributes test:test
      )
      driver = create_driver(conf)
      input = driver.instance

      expected_ldap_attributes = { 'test' => 'test' }
      assert_equal expected_ldap_attributes, input.ldap_attributes
    end

    test 'ldap_attributes should not be empty' do
      conf = %(
        ldap_query test_ldap_query
      )

      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end
  end

  sub_test_case 'filter' do
    test 'add ldap attributes to record' do
      conf = %(
        cache_enable false

        ldap_query test ldap query
        ldap_attributes test_attribute:test_attribute
      )
      messages = [
        { 'test_1' => 'from_input' }
      ]
      expected = [
        { 'test_1' => 'from_input', 'test_attribute' => 'from_ldap' }
      ]

      @ldap_client_mock.expects(:search_query).returns({ test_attribute: ['from_ldap'] })
      @ldap_client_mock.expects(:close)
      Fluent::Plugin::LdapClient::LdapClient.stubs(:new).returns(@ldap_client_mock)

      filtered_records = filter(conf, messages)
      assert_equal(expected, filtered_records)
    end

    test 'returns record when ldap is not available' do
      conf = %(
        cache_enable false

        ldap_query test ldap query
        ldap_attributes test_attribute:test_attribute
      )
      messages = [
        { 'test_1' => 'from_input' }
      ]

      filtered_records = filter(conf, messages)
      assert_equal(messages, filtered_records)
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::LdapEnrichFilter).configure(conf)
  end

  def filter(conf, messages)
    d = create_driver(conf)
    d.run(default_tag: 'test') do
      messages.each do |message|
        d.feed(message)
      end
    end
    d.filtered_records
  end
end
