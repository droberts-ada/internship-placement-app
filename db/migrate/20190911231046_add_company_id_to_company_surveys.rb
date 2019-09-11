class AddCompanyIdToCompanySurveys < ActiveRecord::Migration[5.0]
  def change
    add_reference :company_surveys, :company, references: :companies, index: true, null: false
    add_foreign_key :company_surveys, :companies, column: :company_id
  end
end
