class UsersController < ApplicationController
  skip_before_action :require_login

  def login
    redirect_to 'auth/google_oauth2'
  end

  def auth_callback
    auth_hash = request.env['omniauth.auth']

    user = User.from_omniauth(auth_hash)
    if user.persisted?
      session[:user_id] = user.id

    else
      flash[:status] = :failure
      flash[:message] = "Could not log in"
      flash[:errors] = user.errors.messages

    end

    redirect_to root_path
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path
  end
end
