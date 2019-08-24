class UsersController < ApplicationController
  skip_before_action :require_login

  def login
    redirect_to 'auth/google_oauth2'
  end

  def auth_callback
    auth_hash = request.env['omniauth.auth']

    session[:user_id] = User.from_omniauth(auth_hash).id

    redirect_to root_path
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path
  end
end
