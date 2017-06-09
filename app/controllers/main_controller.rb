class MainController < ApplicationController
  skip_before_action :require_login
  before_action :lookup_user
  
  def index
  end
end
