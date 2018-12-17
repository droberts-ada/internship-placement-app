class RemoveInterviewResultReasonFromRankings < ActiveRecord::Migration[5.0]
  def change
    remove_column :rankings, :interview_result_reason, :string
  end
end
