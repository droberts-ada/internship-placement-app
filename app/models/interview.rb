class Interview < ApplicationRecord
  INTERVIEW_LENGTH = 30.minutes

  belongs_to :student
  belongs_to :company
  has_many :interview_feedbacks, dependent: :destroy
  has_one :ranking, dependent: :destroy

  validates :student, uniqueness: {scope: :company}
  validate :scheduled_in_future, on: :create

  scope :has_feedback, -> do
    self.joins(:interview_feedbacks).distinct
  end

  def has_feedback?
    interview_feedbacks.present?
  end

  def complete?
    scheduled_at + INTERVIEW_LENGTH < Time.now
  end

  def interview_result
    return nil if interview_feedbacks.empty?

    results = interview_feedbacks.map(&:interview_result)

    (results.sum.to_f / results.count).round
  end

  def student_preference
    ranking.student_preference
  end

  def result_explanation
    return nil if interview_feedbacks.empty?

    explanations = interview_feedbacks.map(&:result_explanation)

    explanations.join(' ; ')
  end

  def score
    return 0 if !student_preference || !interview_result

    return student_preference * interview_result
  end

  def done_at
    return scheduled_at + INTERVIEW_LENGTH
  end

  private

  def scheduled_in_future
    if scheduled_at.nil? || !scheduled_at.future?
      errors.add(:scheduled_at, "must be a time in the future")
    end
  end
end
