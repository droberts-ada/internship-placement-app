ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'minitest/reporters'
require 'vcr'
require 'webmock/minitest'

Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

VCR.configure do |config|
  config.cassette_library_dir = 'test/cassettes'
  config.hook_into :webmock
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i(method uri body),
  }
  config.filter_sensitive_data("<GOOGLE_OAUTH_CLIENT_SECRET>") do
    ENV['GOOGLE_OAUTH_CLIENT_SECRET']
  end
end
