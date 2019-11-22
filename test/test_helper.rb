ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'
require 'securerandom'
require 'webmock/minitest'

require 'simplecov'
SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter 'test/' # Tests should not be checked for coverage.
end

Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes" # folder where casettes will be located
  config.hook_into :webmock # tie into this other tool called webmock
  config.default_cassette_options = {
    :record => :new_episodes,    # record new data when we don't have it yet
    :match_requests_on => [:method, :uri, :body], # The http method, URI and body of a request all need to match
  }
  # Don't leave our secrets lying around in a cassette file.
  config.filter_sensitive_data("<GOOGLE_OAUTH_CLIENT_ID>") { ENV["GOOGLE_OAUTH_CLIENT_ID"] }
  config.filter_sensitive_data("<GOOGLE_OAUTH_CLIENT_SECRET>") { ENV["GOOGLE_OAUTH_CLIENT_SECRET"] }
  config.filter_sensitive_data("<AWS_ACCESS_KEY_ID>") { ENV["AWS_ACCESS_KEY_ID"] }
  config.filter_sensitive_data("<AWS_SECRET_ACCESS_KEY>") { ENV["AWS_SECRET_ACCESS_KEY"] }
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  setup do
    OmniAuth.config.test_mode = true
  end

  # Add more helper methods to be used by all tests here...
  def mock_auth_hash(user)
    return {
      provider: user.oauth_provider,
      uid: user.oauth_uid,
      info: {
        name: user.name,
        email: user.email
      },
      credentials: {
        token: SecureRandom.base64(128),
        refresh_token: SecureRandom.base64(64),
        expires_at: Time.now + 8.hours
      }
    }
  end

  def login_user(user)
    auth_hash = OmniAuth::AuthHash.new(mock_auth_hash(user))
    OmniAuth.config.mock_auth[:google_oauth2] = auth_hash

    get auth_callback_path(:google_oauth2)
  end

  def logout_user
    get logout_path
  end

  def with_forgery_protection
    orig = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    yield
  ensure
    ActionController::Base.allow_forgery_protection = orig unless orig.nil?
  end
end
