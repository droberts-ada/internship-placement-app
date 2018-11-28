class Student < ApplicationRecord
  belongs_to :classroom
  has_many :rankings
  has_many :companies, through: :rankings
  has_many :interviews, dependent: :destroy
end
