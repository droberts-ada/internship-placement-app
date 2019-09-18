class RemoveClassroomsIdFromCompanySurveys < ActiveRecord::Migration[5.0]
  def change
    remove_column(:company_surveys, :classrooms_id)
  end
end
