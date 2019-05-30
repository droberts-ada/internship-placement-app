class InterviewFeedbacksController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  before_action :find_interview

  def new
    @interview_feedback = InterviewFeedback.new
  end

  def create
    feedback = InterviewFeedback.new(interview_feedback_params)
    feedback.interview = @interview

    unless feedback.save()
      flash[:status] = :failure
      flash[:message] = "Could not save your feedback"
      flash[:errors] = feedback.errors.messages
    end

    redirect_to company_path(feedback.interview.company)
  end

  private

  def interview_feedback_params
    params.require(:interview_feedback).permit(
      :interviewer_name,
      :interview_result,
      :result_explanation,
      :feedback_technical,
      :feedback_nontechnical)
  end

  def find_interview
    @interview = Interview.find_by(id: params[:interview_id])

    render_not_found if @interview.nil?
  end
end
