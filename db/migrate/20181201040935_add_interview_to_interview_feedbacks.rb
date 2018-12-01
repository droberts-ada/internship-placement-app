class AddInterviewToInterviewFeedbacks < ActiveRecord::Migration[5.0]
  def change
    add_reference :interview_feedbacks, :interview, foreign_key: true
  end
end
