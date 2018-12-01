class InterviewFeedback < ApplicationRecord
  belongs_to :interview

  validates :interviewer_name, :interview_result, :result_explanation, presence: true
  validates :interview_result, numericality: { integer_only: true, greater_than: 0, less_than: 6 }
end
