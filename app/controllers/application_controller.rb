class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :lookup_user

private
  def lookup_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    end
  end

  REFRESH_URL = 'https://accounts.google.com/o/oauth2/token'
  def refresh_token
    # Refresh auth token from google_oauth2.
    # See https://github.com/zquestz/omniauth-google-oauth2/issues/37
    options = {
      body: {
        client_id: ENV["GOOGLE_OAUTH_CLIENT_ID"],
        client_secret: ENV["GOOGLE_OAUTH_CLIENT_SECRET"],
        refresh_token: @current_user.oauth_token},
        grant_type: 'refresh_token'
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    }

    refresh = HTTParty.post(REFRESH_URL, options)

    if refresh.code == 200
      response = refresh.parsed_response
      @current_user.oauth_token = response['access_token']
      @current_user.token_expires_at = Time.now + response['expires_in']
      @current_user.save!
    else
      # TODO: error handling
      raise
    end
  end

  def require_login
    lookup_user
    if @current_user.nil?
      flash[:status] = :failure
      flash[:message] = "You must be logged in to see this page"
      redirect_to root_path

    elsif @current_user.token_expires_at < Time.now
      # TODO DPR: figure out how to refresh a token

      refresh_token
    end
  end
end
