class Company < ApplicationRecord
  belongs_to :classroom
  has_many :rankings
  has_many :students, through: :rankings
  has_many :interviews, dependent: :destroy

  validates :name, presence: true

  validates :slots, numericality: { integer_only: true, greater_than: 0 }

  def interviews_complete?
    interviews.all?(&:has_feedback?)
  end
end
