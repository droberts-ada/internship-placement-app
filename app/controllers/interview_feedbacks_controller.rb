class InterviewFeedbacksController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  before_action :find_interview_feedback, only: [:edit, :update]

  def new
    @interview = Interview.find_by(id: params[:interview_id])

    if @interview.nil?
      render_not_found
    else
      @interview_feedback = InterviewFeedback.new
    end
  end

  def create
    feedback = InterviewFeedback.new(interview_feedback_params)
    feedback.interview_id = params[:interview_id]

    unless feedback.save()
      report_error(
        :bad_request,
        "Could not save your feedback",
        errors: feedback.errors,
        redirect_path: company_path(feedback.interview.company))
    end
  end

  def edit
  end

  def update
    @interview_feedback.update_attributes(interview_feedback_params)

    if @interview_feedback.save
      flash[:status] = :success
      flash[:message] = "Updated feedback for #{@interview.student.name}"
      redirect_to company_path(@interview.company)
    else
      report_error(
        :bad_request,
        "Could not update feedback for #{@interview.student.name}",
        errors: @interview_feedback.errors.messages,
        render_view: :edit)
    end
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

  def find_interview_feedback
    @interview_feedback = InterviewFeedback.find_by(id: params[:id])

    if @interview_feedback.nil?
      render_not_found
    else
      @interview = @interview_feedback.interview
    end
  end
end
