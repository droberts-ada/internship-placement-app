class CompaniesController < ApplicationController
  def index
    @companies = Company.all
  end

  def show
    # TODO: Order by time?
    @interviews = Interview.where(company: params[:company])
  end
end
