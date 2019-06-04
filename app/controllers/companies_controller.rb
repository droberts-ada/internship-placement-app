class CompaniesController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  def index
    @companies = Company.all.reject { |c| c.interviews_complete? }.sort_by { |c| c.name }
  end

  def show
    @company = Company.find_by(id: params[:id])

    if @company.nil?
      render_not_found
    else
      @interviews = @company.interviews.sort_by { |i| i.scheduled_at }
    end
  end
end
