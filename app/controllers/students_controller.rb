class StudentsController < ApplicationController
  skip_before_action :require_login, only: [:feedback, :companies, :rankings]
  skip_before_action :verify_authenticity_token,
                     only: [:rankings]

  before_action :find_student, only: [:companies, :rankings]

  def feedback
    @students = Student.without_feedback.order(name: :asc)
  end

  def companies
    companies = @student.interviews.has_feedback.map(&:company)

    render json: companies.as_json(only: [:id, :name]), status: :ok
  end

  def rankings
    Ranking.transaction do
      params[:rankings].each(&:permit!).map(&:to_h).each do |ranking|
        company_id = ranking[:company_id]
        rank = ranking[:rank]

        company = Company.find(company_id)
        interview = @student.interviews.find_by(company: company)
        if interview.nil?
          raise ActiveRecord::RecordInvalid.new("Invalid company(##{company_id}) for student with ID #{@student.id}")
        end

        @student.rankings.create!(
          company: company,
          student_preference: rank,
          interview_result: interview.interview_result,
        )
      end
    end

    head :no_content
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => ex
    render json: {
      error: ex.message,
    }, status: :bad_request
  end

  private

  def find_student
    @student = Student.find_by(id: params[:id])
    render_not_found if @student.nil?
  end
end
