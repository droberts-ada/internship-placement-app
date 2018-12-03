class CreateInterviewFeedbacks < ActiveRecord::Migration[5.0]
  def change
    create_table :interview_feedbacks do |t|
      t.string :interviewer_name, null: false

      t.integer :interview_result, null: false
      t.text :result_explanation, null: false

      t.text :feedback_technical
      t.text :feedback_nontechnical

      t.timestamps
    end
  end
end
