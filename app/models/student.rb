class Student < ApplicationRecord
  belongs_to :classroom
  has_many :rankings, through: :interviews
  has_many :companies, through: :interviews
  has_many :interviews, dependent: :destroy

  validates :name, presence: true

  scope :without_feedback, -> do
    self.left_outer_joins(:rankings)
      .where(rankings: { id: nil })
      .distinct
  end

  def interviews_complete?
    interviews.all?(&:complete?)
  end
end
