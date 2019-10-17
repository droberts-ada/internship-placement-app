class CompaniesController < ApplicationController
  skip_before_action :require_login, only: [:show, :create_survey]
  skip_before_action :verify_authenticity_token, only: [:show, :create_survey]

  before_action :lookup_company, only: [:show, :create_survey, :update_survey]

  SURVEY_QUESTIONS = [
    {
      text: "How structured and thorough is your planned on-boarding process?",
      name: "onboarding",
      answers: [
        { text: "Very structured", points: 4 },
        { text: "Somewhat structured", points: 3 },
        { text: "Not structured", points: 0 },
        { text: "No onboarding plan", points: 0 }
      ]
    },
    {
      text: "How often do you pair program?",
      name: "pair_programming",
      answers: [
        { text: "Daily", points: 5 },
        { text: "As needed", points: 4 },
        { text: "Twice a week", points: 3 },
        { text: "Weekly", points: 2 },
        { text: "Every two weeks", points: 1 },
        { text: "Rarely/Never", points: 0 }
      ]
    },
    {
      text: "How structured is the day to day? Is this a ticket based team or a team with more discovery/exploratory based development?",
      name: "structure",
      answers: [
        { text: "We use tickets or single day tasks to track individual progress.", points: 5 },
        { text: "Highly structured", points: 3 },
        { text: "Partially structured", points: 2 },
        { text: "Unstructured", points: 0 },
        { text: "We give members of the team large tasks that may take a month or more to complete.", points: 1 }
      ]
    },
    {
      text: "Does this team have other developers from a non-traditional background, such as code boot-camp graduates or other Adies?",
      name: "diverse_bg",
      answers: [
        { text: "Yes, several.", points: 2 },
        { text: "We have at least 1.", points: 1 },
        { text: "This Adie will be our first!", points: 0 }
      ]
    },
    {
      text: "Will your intern work with other Adies?",
      name: "other_adies",
      answers: [
        { text: "Yes", points: 1 },
        { text: "No", points: 0 }
      ]
    },
    {
      text: "How frequently do you expect the Adie to meet with their <strong>mentor</strong>?",
      name: "meet_with_mentor",
      answers: [
        { text: "Daily", points: 4 },
        { text: "Twice Weekly", points: 3 },
        { text: "Weekly", points: 2 },
        { text: "Monthly", points: 1 }
      ]
    },
    {
      text: "How frequently do you expect the Adie to meet with their <strong>team lead</strong>?",
      name: "meet_with_lead",
      answers: [
        { text: "Daily", points: 4 },
        { text: "Twice Weekly", points: 3 },
        { text: "Weekly", points: 2 },
        { text: "Monthly", points: 1 }
      ]
    },
    {
      text: "How frequently do you expect the Adie to meet with their <strong>manager</strong>?",
      name: "meet_with_manager",
      answers: [
        { text: "Daily", points: 4 },
        { text: "Twice Weekly", points: 3 },
        { text: "Weekly", points: 2 },
        { text: "Monthly", points: 1 }
      ]
    },
    {
      text: "What mentorship experience does the mentor already have?",
      name: "mentorship_experience",
      answers: [
        { text: "Mentored previous Adies or interns from non-traditional backgounds.", points: 1 },
        { text: "Mentored other interns/CS new grads", points: 0 },
        { text: "They will be a first time mentor!", points: 0 }
      ]
    },
    {
      text: "How old will this team be when the Adie joins?",
      name: "team_age",
      answers: [
        { text: "A year or more", points: 4 },
        { text: "6 to 11 months", points: 3 },
        { text: "2 to 6 months", points: 2 },
        { text: "A few weeks", points: 1 },
        { text: "Brand new", points: 0 },
      ]
    },
    {
      text: "How large is this team?",
      name: "team_size",
      answers: [
        { text: "2 to 3 people", points: 4 },
        { text: "4 to 6 people", points: 3 },
        { text: "7 to 10 people", points: 2 },
        { text: "More than 10 people", points: 1 },
      ]
    }
  ]

  def index
    @companies_with_interviews = Classroom.order(id: :desc).map do |classroom|
      [classroom, classroom.companies_with_open_surveys + classroom.companies_with_open_interviews]
    end.reject do |classroom, companies|
      companies.empty?
    end
  end

  def show
    @company_survey = CompanySurvey.find_by(company_id: @company.id)
    @interviews = @company.interviews.order(scheduled_at: :asc) # TODO: select only future interviews.

    if @company_survey.nil?
      @company_survey = CompanySurvey.new
      @questions = SURVEY_QUESTIONS
    end
  end

  def create_survey
    survey_points = company_survey_params.to_h.map do |question_name, answer_index|
      question = SURVEY_QUESTIONS.find { |q| q[:name] == question_name }
      answer = question[:answers][answer_index.to_i]
      [question_name, answer[:points]]
    end.to_h

    CompanySurvey.create!(survey_points.merge({company: @company}))

    flash[:status] = :success
    flash[:message] = "Thank you for submitting the survey!"
    redirect_to company_path(@company.uuid)
  rescue ActiveRecord::RecordInvalid => ex
    report_error(:bad_request,
                 "Failed to submit survey",
                 errors: {company_survey: [ex.message]},
                 render_view: :show)
  end

  private

  def lookup_company
    @company = Company.find_by(uuid: params[:id])

    return render_not_found if @company.nil?
  end

  def company_survey_params
    params.require(:company_survey).permit(
      :onboarding,
      :pair_programming,
      :structure,
      :diverse_bg,
      :other_adies,
      :meet_with_mentor,
      :meet_with_lead,
      :meet_with_manager,
      :mentorship_experience,
      :team_age,
      :team_size
    )
  end
end
