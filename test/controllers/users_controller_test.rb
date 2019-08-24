require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  describe UsersController do
    it "can login" do
      get login_path

      assert_response :redirect
      must_redirect_to 'auth/google_oauth2'
    end

    it "handles invalid credentials" do
      OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

      get auth_callback_path(:google_oauth2)

      assert_response :redirect
    end

    it "can logout" do
      # We can't access session in Rails 5.
      get logout_path

      assert_response :redirect
      must_redirect_to root_path
      expect(flash[:status]).must_be_nil
    end
  end
end
