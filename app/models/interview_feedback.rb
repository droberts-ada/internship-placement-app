class InterviewFeedback < ApplicationRecord
  validates :interviewer_name, :interview_result, :result_explanation, presence: true
end
