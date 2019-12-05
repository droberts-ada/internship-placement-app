class CleanUpOldRankingColumns < ActiveRecord::Migration[5.0]
  def change
    has_student = false
    has_company = false
    has_result = false

    Ranking.transaction do
      has_student = Ranking.first.respond_to? :student_id
      has_company = Ranking.first.respond_to? :company_id
      has_result = Ranking.first.respond_to? :interview_result_id
    end

    change_column :rankings, :interview_id, :integer, null: false
    remove_column :rankings, :student_id if has_student
    remove_column :rankings, :company_id if has_company
    remove_column :rankings, :interview_result if has_result
  end
end
