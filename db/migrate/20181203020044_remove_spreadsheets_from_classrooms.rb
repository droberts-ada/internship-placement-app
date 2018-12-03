class RemoveSpreadsheetsFromClassrooms < ActiveRecord::Migration[5.0]
  def change
    remove_column :classrooms, :interview_result_spreadsheet, :string
    remove_column :classrooms, :student_preference_spreadsheet, :string
  end
end
