class CompanySurveySerializer
  HEADERS = [
    "company name",
    "team name",
    "hiring requirements",
    "preferred students",
    "overall score"
  ] + CompaniesController::SURVEY_QUESTIONS.map {|q| "#{q[:name]} - #{q[:text]}"}

  def initialize(surveys)
    raise ArgumentError.new('Company Surveys are required') unless surveys

    @surveys = surveys
  end

  def to_csv
    CSV.generate do |csv|
      csv << HEADERS

      @surveys.each do |feedback|
        csv << row(feedback)
      end
    end
  end

  private

  def row(survey)
    [
      survey.company.name,
      survey.team_name,
      survey.pre_hiring_requirements,
      survey.preferred_students,
      survey.score
    ] + CompaniesController::SURVEY_QUESTIONS.map {|q| survey[q[:name]]}
  end
end
