ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'
require 'securerandom'

Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

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

  def typeform_id
    SecureRandom.base64(6)
  end

  def with_forgery_protection
    orig = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    yield
  ensure
    ActionController::Base.allow_forgery_protection = orig unless orig.nil?
  end
end
