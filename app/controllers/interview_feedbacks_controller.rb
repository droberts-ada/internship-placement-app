class InterviewFeedbacksController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  before_action :find_interview_feedback

  def new
    @interview = Interview.find_by(id: params[:id])

    if @interview.nil?
      render_not_found
    end
  end

  def create
    @interview = Interview.find_by(id: params[:interview_id])

    if @interview.nil?
      render_not_found
    else
      feedback = InterviewFeedback.new(interview_feedback_params)

      if feedback.save()
        render file: 'public/feedback_thanks.html', status: :success
      else
        flash[:status] = :failure
        flash[:message] = "Could not save your feedback"
        flash[:errors] = feedback.errors.messages

        redirect_back
      end
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
    @student = Student.find_by(id: params[:id])
    render_not_found if @student.nil?
  end
end
