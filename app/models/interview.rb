class Interview < ApplicationRecord
  belongs_to :student
  belongs_to :company

  validates :student, uniqueness: {scope: :company}
  validate :scheduled_in_future

  private

  def scheduled_in_future
    if scheduled_at.nil? || !scheduled_at.future?
      errors.add(:scheduled_at, "must be a time in the future")
    end
  end
end
