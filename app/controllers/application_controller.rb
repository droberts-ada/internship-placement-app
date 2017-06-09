class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :require_login

private
  def lookup_user
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    end
  end

  REFRESH_URL = 'https://accounts.google.com/o/oauth2/token'
  def refresh_token
    # Refresh auth token from google_oauth2
    # See https://github.com/zquestz/omniauth-google-oauth2/issues/37
    options = {
      body: {
        client_id: ENV["GOOGLE_OAUTH_CLIENT_ID"],
        client_secret: ENV["GOOGLE_OAUTH_CLIENT_SECRET"],
        refresh_token: @current_user.refresh_token,
        grant_type: 'refresh_token'
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    }

    puts
    puts "Refreshing oauth token for user #{@current_user.email}"

    refresh = HTTParty.post(REFRESH_URL, options)

    puts "Got response for refresh"
    puts refresh
    puts

    if refresh.code == 200
      response = refresh.parsed_response
      @current_user.oauth_token = response['access_token']
      @current_user.token_expires_at = Time.now + response['expires_in']
      unless @current_user.save
        flash[:status] = :failure
        flash[:message] = "Refreshed user auth token, but could not write to database!"
        flash[:errors] = @current_user.errors.messages
        render 'main/index'
      end
    else
      flash[:status] = :failure
      flash[:message] = "Refreshing user auth token failed with status \'#{refresh['error']}\': #{refresh['error_description']}"
      render 'main/index'
    end
  end

  def require_login
    lookup_user
    if @current_user.nil?
      flash[:status] = :failure
      flash[:message] = "You must be logged in to see this page"
      redirect_to root_path

    elsif @current_user.token_expires_at < Time.now
      # Token is expired -> need to refresh
      refresh_token

    end
  end
end
