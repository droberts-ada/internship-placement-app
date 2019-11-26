class InterviewsController < ApplicationController
  before_action :lookup_company

  def new
    @interview = Interview.new
  end

  def create
    @interview = Interview.new  # For rendering /new

    student_name = params[:student_name]
    if student_name
      @student = Student.find_or_create_by!(name: student_name, classroom: @company.classroom)
      Interview.create!({student: @student, company: @company}.merge(interview_params))

      flash[:status] = :success
      flash[:message] = "Interview successfully scheduled!"
      redirect_to company_path(@company.uuid)
    else
      report_error(:bad_request,
                   "Failed create create interview, student_name is required!",
                   errors: [],
                   render_view: :new)
    end
    rescue ActiveRecord::RecordInvalid => ex
    report_error(:bad_request,
                 "Failed to schedule interview #{ex.message}",
                 render_view: :new)
  end

  private

  def interview_params
    params.require(:interview).permit(:company_id, :student_id, :scheduled_at)
  end

  def lookup_company
    @company = Company.find_by(uuid: params[:company_id])

    return render_not_found if @company.nil?
  end
end
