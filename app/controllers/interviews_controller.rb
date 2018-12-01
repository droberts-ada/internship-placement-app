class InterviewsController < ApplicationController
  skip_before_action :require_login,
                     only: [:feedback]

  def feedback
    render plain: 'Success', status: :ok
  end
end
