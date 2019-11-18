class AddPreHiringRequirementsToCompanySurvey < ActiveRecord::Migration[5.0]
  def change
    add_column(:company_surveys, :pre_hiring_requirements, :string)
  end
end
