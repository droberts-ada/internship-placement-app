class StudentsController < ApplicationController
  skip_before_action :require_login, only: [:feedback, :companies]

  before_action :find_student, only: [:companies]

  def feedback
    @students = Student.without_feedback.order(name: :asc)
  end

  def companies
    companies = @student.interviews.has_feedback.map(&:company)

    render json: companies.as_json(only: [:id, :name]), status: :ok
  end

  private

  def find_student
    @student = Student.find_by(id: params[:id])
    render_not_found if @student.nil?
  end
end
