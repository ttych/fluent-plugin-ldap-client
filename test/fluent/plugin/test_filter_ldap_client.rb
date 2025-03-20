# frozen_string_literal: true

require 'helper'
require 'fluent/plugin/filter_ldap_enrich'

class LdapEnrichFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test 'nothing' do
    true
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::LdapEnrichFilter).configure(conf)
  end
end
