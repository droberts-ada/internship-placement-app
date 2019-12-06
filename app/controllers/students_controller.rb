require 'mail'

class StudentsController < ApplicationController
  skip_before_action :require_login, only: [:feedback, :companies, :rankings]
  skip_before_action :verify_authenticity_token,
                     only: [:rankings]

  before_action :find_student, only: [:companies, :rankings]

  BUCKETS = [nil, 1, 4, 4, 5, 5, 5].freeze

  CONFIRMATION_EMAIL_SENDER = "lisa@adadevelopersacademy.org"
  CONFIRMATION_EMAIL_SUBJECT = "Ada Interviews: Confirmation Email"
  CONFIRMATION_EMAIL_TEMPLATE = "<p>Hello %{name}</p>
<p>Thank you for submitting your rankings they are as follows:<p>
<p>Very Interested</p>
<ul>
  <li>%{ranking0}</li>
  <li>%{ranking1}</li>
  <li>%{ranking2}</li>
</ul>
<p>Interested</p>
<ul>
  <li>%{ranking3}</li>
  <li>%{ranking4}</li>
</ul>
<p>Somewhat Interested</p>
<ul>
  <li>%{ranking5}</li>
</ul>
<p>Best,<br><br>
<img src=\"https://adadevelopersacademy.org/wp-content/uploads/2019/08/logo.png\"
     alt=\"Ada Developers Academy\"
     width=250>
</p>"

  def feedback
    @students = Student.without_feedback
                  .order(name: :asc)
                  .select(&:interviews_complete?)
                  .select { |s| s.interviews.length > 0 }
  end

  def companies
    companies = @student.interviews.map(&:company)

    render json: companies.as_json(only: [:id, :name]), status: :ok
  end

  def rankings
    email = nil

    unless params[:email].nil? || params[:email].empty?
      if VALID_EMAIL_REGEXP.match?(params[:email])
        email = params[:email]
      else
        render json: {
                 error: "Invalid email address: #{params[:email]}",
               }, status: :bad_request
        return
      end
    end

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

    if email
      send_confirmation(email)
    end
  rescue ActiveRecord::RecordNotFound => ex
    render json: {
             error: ex.message,
           }, status: :bad_request
  end

  def send_confirmation(email)
    rankings = @student.rankings.includes(:interview).map { |ranking| ranking.interview.company.name }

    body = sprintf(
      CONFIRMATION_EMAIL_TEMPLATE,
      name: @student.name,
      ranking0: rankings[0],
      ranking1: rankings[1],
      ranking2: rankings[2],
      ranking3: rankings[3],
      ranking4: rankings[4],
      ranking5: rankings[5]
    )

    send_email(sender: CONFIRMATION_EMAIL_SENDER,
               recipients: [email],
               subject: CONFIRMATION_EMAIL_SUBJECT,
               html_body: body)
  end

  private

  def find_student
    @student = Student.find_by(id: params[:id])
    render_not_found if @student.nil?
  end
end
