class StudentsController < ApplicationController
  skip_before_action :require_login, only: [:feedback, :companies, :rankings]
  skip_before_action :verify_authenticity_token,
                     only: [:rankings]

  before_action :find_student, only: [:companies, :rankings]

  BUCKETS = [nil, 1, 4, 4, 5, 5, 5].freeze

  def feedback
    @students = Student.without_feedback
                  .order(name: :asc)
                  .select(&:interviews_complete?)
                  .select { |s| s.interviews.length > 0 }
  end

  def companies
    companies = @student.interviews.has_feedback.map(&:company)

    render json: companies.as_json(only: [:id, :name]), status: :ok
  end

  def rankings
    Ranking.transaction do
      rankings = params[:rankings].each(&:permit!).map(&:to_h)
      ranks = rankings.map { |r| r[:rank].to_i }.sort

      if ranks == (1..rankings.length).to_a
        rankings.each do |ranking|
          company_id = ranking[:company_id]

          rank = BUCKETS[ranking[:rank].to_i]

          company = Company.find(company_id)
          interview = @student.interviews.find_by(company: company)
          if interview.nil?
            raise ActiveRecord::RecordNotFound.new("Invalid company(##{company_id}) for student with ID #{@student.id}")
          end

          Ranking.create!(
            interview: interview,
            student_preference: rank
          )
        end

        head :no_content
      else
        render json: {
                 error: "Invalid rankings.  Rank must be 1 to #{rankings.length} and were: #{ranks}",
               }, status: :bad_request
      end
    end

  rescue ActiveRecord::RecordNotFound => ex
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
