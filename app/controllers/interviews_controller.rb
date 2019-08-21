class InterviewsController < ApplicationController
  skip_before_action :require_login, only: [:index, :show, :feedback]

  skip_before_action :verify_authenticity_token,
                     only: [:feedback]

  before_action :verify_typeform_secret,
                :ignore_test_requests,
                only: [:feedback]

  def index
    # Do we have a specific date?
    @date = (params[:date] || Date.today).to_date
    time_range = @date.beginning_of_day..@date.end_of_day

    # Do we have a specific company?
    @company = Company.find_by(uuid: params[:company_id])

    if @company
      @interviews = Interview.where(
                      scheduled_at: time_range,
                      company: @company
                    ).order(scheduled_at: :asc)
    else
      @companies = Company.all
                          .joins(:interviews)
                          .merge(Interview.where(scheduled_at: time_range))
                          .order(name: :asc)
                          .distinct
    end

    @dates = Interview.all.pluck(:scheduled_at).sort.map(&:to_date).uniq
  end

  def show
    interview = Interview.find(params[:id])

    form_params = {
      interview_id: interview.id,
      student_name: interview.student.name,
      company_name: interview.company.name,
      scheduled_at: interview.scheduled_at.to_s(:time_12hr),
      redirect_to: request.referrer || interviews_path
    }

    form_url = URI.parse(ENV['TYPEFORM_INTERVIEW_FORM'])
    form_url.query = URI.encode_www_form(form_params)

    redirect_to form_url.to_s, status: 302
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  helper_method :search_params
  def search_params
    params.permit(:date, :company_id)
  end

  def log_error(messages)
    logger.error messages.prepend('Interview Feedback error:')
                         .push('Request Data:', params.to_h.inspect)
                         .join($/)
  end
end
