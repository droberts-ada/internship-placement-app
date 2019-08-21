class CompaniesController < ApplicationController
  skip_before_action :require_login, only: [:show]
  skip_before_action :verify_authenticity_token, only: [:show]

  def index
    @companies = Company.all.reject { |c| c.interviews_complete? }.sort_by { |c| c.name }
  end

  def show
    @company = Company.find_by(uuid: params[:id])

    if @company.nil?
      render_not_found
    else
      @interviews = @company.interviews.order(scheduled_at: :asc)
    end
  end
end
