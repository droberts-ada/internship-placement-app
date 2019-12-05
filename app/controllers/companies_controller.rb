# coding: utf-8
require 'aws-sdk'

class CompaniesController < ApplicationController
  skip_before_action :require_login, only: [:show, :create_survey]
  skip_before_action :verify_authenticity_token, only: [:show, :create_survey]

  before_action :lookup_company, except: [:index, :new, :create]

  CLASSES_PER_COHORT = 2

  REMINDER_EMAIL_SENDER = "lisa@adadevelopersacademy.org"
  REMINDER_EMAIL_SUBJECT = "Action Required: Ada Cohort 12 Interview Feedback"
  REMINDER_EMAIL_TEMPLATE = "<p>Hello %{name}!</p>
  <p>Thank you for taking time to interview our students!</p>
  <p>This is a reminder to submit your interview feedback as soon as possible. Your feedback plays a critical role in determining the placement of our students. In order to create and share the internship matches on time, we need to receive all of your feedback.</p>
  <p>You can access your unfinished feedback via your YOUR <a href=\"%{link}\">personalized link</a>.</p>
  <p>Feedback link: %{link}</p>
  <p>Thank you!<br><br>
  <img src=\"https://adadevelopersacademy.org/wp-content/uploads/2019/08/logo.png\"
       alt=\"Ada Developers Academy\"
       width=250>
  </p>"

  # TODO: Split into own controller!
  # TODO: Allow editing!
  SURVEY_EMAIL_SENDER = "lisa@adadevelopersacademy.org"
  SURVEY_EMAIL_SUBJECT = "Ada Cohort 12 Internship Survey [Due 11/21 EOD]"
  SURVEY_EMAIL_TEMPLATE = "<p>Hello %{name}!</p>
  <p>Here's YOUR <a href=\"%{link}\">personalized link</a> to the internship support survey. It is our goal to make the best placement possible you and the intern and we hope this survey will aid in that attempt.  Please respond to the best of your ability as your answers will be used to ensure the best fit at your company.</p>

  <p>You will have the opportunity to request up to four students per internship slot to interview in the third question.  We will take your requests into consideration, but cannot guarantee that you will be able to interview or be matched with all of the students that you list. For your reference, we have provided a link to the students’ <a href=\"https://docs.google.com/spreadsheets/d/1s7P2xeKnxa7-uY6mSjIWq7rny7r3GvAOXewXOXKThpM/edit#gid=0\">resumes and bios</a>.<p>

  <p>Survey link: %{link}</p>
  <p>Resume and Bio link: https://docs.google.com/spreadsheets/d/1s7P2xeKnxa7-uY6mSjIWq7rny7r3GvAOXewXOXKThpM/edit#gid=0</p>

  <p>The survey link will function throughout interview week and is how you will provide interview feedback. Please reach out if you have any questions.</p>
  <p>Best,<br><br>
  <img src=\"https://adadevelopersacademy.org/wp-content/uploads/2019/08/logo.png\"
       alt=\"Ada Developers Academy\"
       width=250>
  </p>"

  # TODO: Move into yaml?
  SURVEY_QUESTIONS = [
    {
      text: "How structured and thorough is your company's/team's planned on-boarding process?",
      name: "onboarding",
      answers: [
        { text: "Very structured", points: 4 },
        { text: "Somewhat structured", points: 3 },
        { text: "Not structured", points: 0 },
        { text: "No onboarding plan", points: 0 }
      ]
    },
    {
      text: "How often does your team pair program?",
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
        { text: "We have at least one.", points: 1 },
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
        { text: "Monthly", points: 1 },
        { text: "Not applicable, i.e. the manager is the team lead, they will not meet with the team lead, etc." , points: 2 }
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
      text: "What management experience does the hiring <strong>manager</strong> already have?",
      name: "manager_experience",
      answers: [
        { text: "Managed previous Adies or interns from non-traditional backgrounds.", points: 1 },
        { text: "Managed other interns/new CS grads", points: 0 },
        { text: "They will be a first time manager!", points: 0 }
      ]
    },
    {
      text: "What mentorship experience does the <strong>mentor</strong> already have?",
      name: "mentorship_experience",
      answers: [
        { text: "Mentored previous Adies or interns from non-traditional backgrounds.", points: 1 },
        { text: "Mentored other interns/CS new grads", points: 0 },
        { text: "They will be a first time mentor!", points: 0 }
      ]
    },
    {
      text: "How old will this team be when the intern starts?",
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
      text: "How many people are on the team?",
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
    flash[:referrer] = request.referrer

    # TODO: Use some joins here!  (Rails has `left_join` and `left_outer_join`.)
    @companies_with_interviews = Classroom.current.includes(companies: [:company_survey, {interviews: :interview_feedbacks}]).order(id: :desc).map do |classroom|
      [classroom, classroom.companies.sort_by(&:name)]
    end.reject do |classroom, companies|
      companies.empty?
    end
  end

  def show
    if @company.redirect_to
      redirect_to company_path(@company.redirect_to)
    else
      @company_survey = @company.company_survey
      @interviews = @company.interviews.sort_by(&:scheduled_at)

      if @company_survey.nil?
        @company_survey = CompanySurvey.new
        @questions = SURVEY_QUESTIONS
      end
    end
  end

  def new
    @company = Company.new(slots: Company::DEFAULT_SLOTS)
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      flash[:status] = :success
      flash[:message] = "Company successfully created!"

      send_survey if params[:commit] && params[:commit].downcase.include?("send")

      redirect_to company_path(@company.reload.uuid)
    else
      report_error(:bad_request,
                   "Failed create create company",
                   errors: @company.errors.messages.map {|message| [:company, message] },
                   render_view: :new)
    end
  end

  def edit
    @company_survey = @company.company_survey
    @questions = []             # Can't edit numeric questions.

    flash[:referrer] = request.referrer
  end

  def update
    if @company.update(company_params)
      flash[:status] = :success
      flash[:message] = "Company successfully updated!"

      send_survey if params[:commit] && params[:commit].downcase.include?("send")

      redirect_to(flash[:referrer] || companies_path)
    else
      report_error(:bad_request,
                   "Failed to update company",
                   errors: @company.errors.messages.map {|message| [:company, message] },
                   render_view: :edit)
    end
  end

  def send_reminder
    name = @company.name
    name = @company.company_survey.team_name if @company.company_survey

    body = sprintf(REMINDER_EMAIL_TEMPLATE,
                   name: name,
                   link: company_url(@company.uuid))

    send_email(sender: REMINDER_EMAIL_SENDER,
               recipients: @company.emails,
               subject: REMINDER_EMAIL_SUBJECT,
               html_body: body)

    redirect_to(companies_path)
  end

  # TODO: Split into own conroller!
  def create_survey
    CompanySurvey.create!(company_survey_args)

    flash[:status] = :success
    flash[:message] = "Thank you for submitting the survey!"
    redirect_to company_path(@company.uuid)
  rescue ActiveRecord::RecordInvalid => ex
    report_error(:bad_request,
                 "Failed to submit survey: #{ex.message}",
                 render_view: :show)
  end

  # TODO: Split into own controller!
  def update_survey
    survey = @company.company_survey
    if survey
      survey.update!(company_survey_args)

      flash[:status] = :success
      flash[:message] = "Survey successfully updated!"
      redirect_to company_path(@company.uuid)
    else
      render_not_found
    end
  rescue ActiveRecord::RecordInvalid => ex
    report_error(:bad_request,
                 "Failed to update survey",
                 errors: {company_survey: [ex.message]},
                 render_view: :show)
  end

  private

  # TODO: Split into own controller!
  def send_survey
    @company.save
    @company.reload

    body = sprintf(SURVEY_EMAIL_TEMPLATE,
                   name: @company.name,
                   link: company_url(@company.uuid))

    send_email(sender: SURVEY_EMAIL_SENDER,
               recipients: @company.emails,
               subject: SURVEY_EMAIL_SUBJECT,
               html_body: body)
  end

  def lookup_company
    @company = Company.where(uuid: params[:id]).includes(interviews: [:interview_feedbacks, :student]).first

    return render_not_found if @company.nil?
  end

  # TODO: Split into own controller!
  def survey_points
    points_params = params.require(:company_survey).permit(
      :onboarding,
      :pair_programming,
      :structure,
      :diverse_bg,
      :other_adies,
      :meet_with_mentor,
      :meet_with_lead,
      :meet_with_manager,
      :manager_experience,
      :mentorship_experience,
      :team_age,
      :team_size
    )

    return points_params.to_h.map do |question_name, answer_index|
      question = SURVEY_QUESTIONS.find { |q| q[:name] == question_name }

      if answer_index.nil?
        answer_points = nil
      else
        answer_points = question[:answers][answer_index.to_i][:points]
      end

      [question_name, answer_points]
    end.to_h
  end

  # TODO: Split into own controller!
  def other_answers
    other_params = params.require(:company_survey).permit(
      :team_name,
      :pre_hiring_requirements,
      :preferred_students)

    return {
      team_name: other_params[:team_name],
      pre_hiring_requirements: other_params[:pre_hiring_requirements],
      preferred_students: other_params[:preferred_students]
    }
  end

  # TODO: Split into own controller!
  def company_survey_args
    survey_points.merge(other_answers).merge(company: @company)
  end

  def company_params
    parsed = params.require(:company).permit(:name, :classroom_id, :slots, :redirect_to, :emails, emails: [])

    parsed[:redirect_to] = nil if parsed[:redirect_to].nil? || parsed[:redirect_to].empty?

    emails = parsed[:emails]
    emails = emails.first if emails.kind_of? Array # Unbox Rails's 1 element arrays.
    if emails
      parsed[:emails] = emails.split(/\s*,\s*/)
    end

    return parsed
  end
end
