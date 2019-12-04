class Pairing < ApplicationRecord
  belongs_to :placement
  belongs_to :company
  belongs_to :student

  validates :student, uniqueness: {scope: :placement}
  validate :company_not_full
  validate :student_interviewed_with_company

  def company_not_full
    # Will error unless we have a company and a placement.
    # belongs_to validates that the company exists, so
    # we don't do that explicitly here.
    return unless self.company and self.placement

    company_pairings = self.placement.pairings.where(company: self.company).length
    if company_pairings >= self.company.slots
      errors.add(:company, "company #{self.company.name}'s #{self.company.slots} slots are already full")
    end
  end

  def student_interviewed_with_company
    return unless self.company and self.student
    if Interview.where(student: self.student, company: self.company).empty?
      errors.add(:match, "student #{self.student.name} did not interview with company #{self.company.name}")
    end
  end
end
