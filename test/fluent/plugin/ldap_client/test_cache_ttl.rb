# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/ldap_client/no_cache'

class TestBusiness
  def test_business
    true
  end
end

class CacheTTLTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup

    @cache = Fluent::Plugin::LdapClient::CacheTTL.new
    @test_business = TestBusiness.new
  end

  sub_test_case 'cache behavior' do
    test 'it forward first call and cache' do
      @test_business.expects(:test_business).times(1)

      5.times do
        @cache.get('test') do |*args|
          @test_business.test_business(*args)
        end
      end
    end
  end

  sub_test_case 'cache size' do
    test 'it forward first call and cache' do
      @test_business.expects(:test_business).times(1)

      5.times do
        @cache.get('test') do |*args|
          @test_business.test_business(*args)
        end
      end
    end
  end
end
