class Interview < ApplicationRecord
  belongs_to :student
  belongs_to :company
  has_many :interview_feedbacks, dependent: :destroy

  validates :student, uniqueness: {scope: :company}
  validate :scheduled_in_future, on: :create

  scope :has_feedback, -> do
    self.joins(:interview_feedbacks).distinct
  end

  def has_feedback?
    interview_feedbacks.present?
  end

  private

  def scheduled_in_future
    if scheduled_at.nil? || !scheduled_at.future?
      errors.add(:scheduled_at, "must be a time in the future")
    end
  end
end
