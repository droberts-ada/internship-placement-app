class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :require_login

  def render_not_found
    render file: 'public/404.html', status: :not_found
  end

private
  def report_error(code, message, errors: [], redirect_path: root_path, render_view: nil)
    respond_to do |format|
      format.html do
        if render_view
          flash.now[:status] = :failure
          flash.now[:message] = message
          flash.now[:errors] = errors

          render render_view, status: code
        elsif redirect_path
          flash[:status] = :failure
          flash[:message] = message
          flash[:errors] = errors

          redirect_to redirect_path
        end
      end
      format.json do
        response = {
          status: :failure,
          message: message
        }
        response[:errors] = errors
        render status: code, json: response
      end
    end
  end

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

      @current_user.save!
    else
      report_error(:unauthorized,
          "Refreshing user auth token failed with status \'#{refresh['error']}\': #{refresh['error_description']}",
          render_view: 'main/index')
    end
  end

  def require_login
    lookup_user
    if @current_user.nil?
      report_error(:unauthorized,
          "You must be logged in to see this page",
          redirect_path: root_path)

    elsif @current_user.token_expires_at < Time.now
      # Token is expired -> need to refresh
      refresh_token
    end
  end
end
