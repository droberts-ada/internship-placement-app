class Classroom < ApplicationRecord
  has_many :students
  has_many :rankings, through: :students
  has_many :companies
  has_many :placements
  has_many :pairings, through: :placements
  belongs_to :creator, class_name: "User"

  end
end
