class AddPreferredStudentsToCompanySurveys < ActiveRecord::Migration[5.0]
  def change
    add_column(:company_surveys, :preferred_students, :string)
  end
end
