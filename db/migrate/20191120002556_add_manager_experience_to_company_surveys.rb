class AddManagerExperienceToCompanySurveys < ActiveRecord::Migration[5.0]
  def change
    add_column(:company_surveys, :manager_experience, :integer, null: false)
  end
end
