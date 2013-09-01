require 'coveralls'
Coveralls.wear!

ENV["RACK_ENV"] = 'test'

require "rack/test"
require "webmock/rspec"
require "factory_girl"
require_relative "../application.rb"

module RSpecMixin
  include Rack::Test::Methods
  def app() HpsBioApp end
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.mock_with :rr
end

unless defined?(SPEC_CONSTANTS)
  FG = FactoryGirl
  SPEC_CONSTANTS = true
end

FG.find_definitions

