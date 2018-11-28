class Interview < ApplicationRecord
  belongs_to :student
  belongs_to :company

  validates :student, uniqueness: {scope: :company}
end
