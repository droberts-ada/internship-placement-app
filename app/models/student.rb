class Student < ApplicationRecord
  belongs_to :classroom
  has_many :rankings
  has_many :companies, through: :rankings
  has_many :interviews, dependent: :destroy

  validates :name, presence: true

  scope :without_feedback, -> do
    self.left_outer_joins(:rankings)
        .where(rankings: { id: nil })
        .distinct
  end

  def interviews_complete?
    interviews.all?(&:has_feedback?)
  end
end
