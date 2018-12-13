class Ranking < ApplicationRecord
  belongs_to :student
  belongs_to :company

  validates :student, uniqueness: {scope: :company}

  # numericality implies presence: true
  validates :student_preference, numericality: {
    only_integer: true,
    greater_than: 0,
  }
  validates :interview_result, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: 5
  }

  def score
    student_preference + interview_result
  end
end
