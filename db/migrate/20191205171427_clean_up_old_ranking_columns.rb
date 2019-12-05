class CleanUpOldRankingColumns < ActiveRecord::Migration[5.0]
  def change
    change_column :rankings, :interview_id, :integer, null: false
    remove_column :rankings, :student_id if Ranking.first.respond_to? :student_id
    remove_column :rankings, :company_id if Ranking.first.respond_to? :company_id
    remove_column :rankings, :interview_result if Ranking.first.respond_to? :interview_result
  end
end
