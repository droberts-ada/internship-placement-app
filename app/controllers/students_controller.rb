class StudentsController < ApplicationController
  skip_before_action :require_login, only: [:feedback]

  def feedback
    @students = Student.without_feedback.order(name: :asc)
  end
end
