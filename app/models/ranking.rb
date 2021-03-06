class Ranking < ApplicationRecord
  belongs_to :interview
  validates_uniqueness_of :interview

  # numericality implies presence: true
  validates :student_preference, numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 5
            }

  def interview_result_reason
    return nil unless interview && interview.has_feedback?

    interview.interview_feedbacks.order(updated_at: :asc).map(&:result_explanation).join("\n")
  end

  def interview_result 
    return self.interview.interview_result
  end

  def company_id
    return self.interview.company_id
  end

  def score
    return 0 if !self.interview_result || !self.student_preference
    
    return self.interview_result * self.student_preference
  end
end
