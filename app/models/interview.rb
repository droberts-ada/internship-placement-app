class Interview < ApplicationRecord
  belongs_to :student
  belongs_to :company
  has_one :interview_feedback, dependent: :destroy

  validates :student, uniqueness: {scope: :company}
  validate :scheduled_in_future, on: :create

  scope :has_feedback, -> do
    self.joins(:interview_feedbacks).distinct
  end

  def has_feedback?
    interview_feedback.present?
  end

  def interview_result
    interview_feedback && interview_feedback.interview_result
  end

  private

  def scheduled_in_future
    if scheduled_at.nil? || !scheduled_at.future?
      errors.add(:scheduled_at, "must be a time in the future")
    end
  end
end
