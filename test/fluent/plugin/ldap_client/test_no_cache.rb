# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/ldap_client/no_cache'

class TestBusiness
  def test_business
    true
  end
end

class NoCacheTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup

    @cache = Fluent::Plugin::LdapClient::NoCache.new
    @test_business = TestBusiness.new
  end

  sub_test_case 'cache behavior' do
    test 'it forward call and do not cache' do
      @test_business.expects(:test_business).times(5)

      5.times do
        @cache.get('test') do |*args|
          @test_business.test_business(*args)
        end
      end
    end
  end
end
