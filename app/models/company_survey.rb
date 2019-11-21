class CompanySurvey < ApplicationRecord
  belongs_to :company
  validates(
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
    :team_size,
    presence: true
  )

  def score
    CompaniesController::SURVEY_QUESTIONS.map {|q| self[q[:name]]}.sum
  end
end
