class Student < ApplicationRecord
  belongs_to :classroom
  has_many :rankings, dependent: :destroy
  has_many :companies, through: :rankings
end
