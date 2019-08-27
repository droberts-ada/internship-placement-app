class Classroom < ApplicationRecord
  has_many :students
  has_many :rankings, through: :students
  has_many :companies
  has_many :placements
  has_many :pairings, through: :placements
  belongs_to :creator, class_name: "User"

  validates :name, :interviews_per_slot, presence: true

  def setup_from_interviews!(interviews)
    # Create companies w/ correct # of slots
    company_names = interviews.transpose.second.map(&:strip)
    company_attrs = company_names.reduce({}) do |slots, n|
      slots.merge(n => slots.fetch(n, 0) + 1)
    end.map do |name, slots|
      { name: name, slots: slots / interviews_per_slot }
    end

    companies.create!(company_attrs)

    # Create each interview
    interviews.each do |student, company, at|
      # TODO: convert time if needed

      Interview.create!(
        student: students.find_or_create_by!(name: student&.strip),
        company: companies.find_by(name: company&.strip),
        scheduled_at: at
      )
    end
  end
end
