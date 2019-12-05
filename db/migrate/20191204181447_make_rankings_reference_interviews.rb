class MakeRankingsReferenceInterviews < ActiveRecord::Migration[5.0]
  def change
    add_reference :rankings, :interview, index: true

    Ranking.all.each do |ranking|
      ranking.interview = Interview.find_by(student_id: ranking.student_id, company_id: ranking.company_id)
      ranking.save
    end

    # change_column :rankings, :interview_id, :integer, null: false
    # remove_column :rankings, :student_id
    # remove_column :rankings, :company_id
    # remove_column :rankings, :interview_result
  end
end
