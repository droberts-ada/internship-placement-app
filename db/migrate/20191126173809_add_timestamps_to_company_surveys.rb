class AddTimestampsToCompanySurveys < ActiveRecord::Migration[5.0]
  def change
    add_timestamps(:company_surveys, default: DateTime.now)
    change_column_default :company_surveys, :created_at, from: DateTime.now, to: nil
    change_column_default :company_surveys, :updated_at, from: DateTime.now, to: nil
  end
end
