class AddTeamNameToCompanySurvey < ActiveRecord::Migration[5.0]
  def change
    add_column(:company_surveys, :team_name, :string)
  end
end
