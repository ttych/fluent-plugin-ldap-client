# frozen_string_literal: true

require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter]
)

SimpleCov.start do
  add_filter '/test/'
end

$LOAD_PATH.unshift(File.expand_path('..', __dir__))

require 'test-unit'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/test/helpers'

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

require 'timecop'
require 'mocha/test_unit'
