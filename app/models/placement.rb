require 'solver'

class Placement < ApplicationRecord
  belongs_to :classroom
  belongs_to :owner, class_name: "User"
  has_many :pairings
  has_many :students, through: :classroom
  has_many :companies, through: :classroom

  # Replace all pairings for this placement
  #
  # new_pairings should be an array of pairings, of form
  #   [ { company_id: 123, student_id: 456 }, ... ]
  #
  # If new_pairings is omitted, all current pairings
  #   will be destroyed.
  #
  # Will rollback and throw an ActiveRecord::RecordInvalid
  #   if any of the pairings is invalid.
  #
  # Returns an ActiveRecord::Collection representing
  #   this placement's pairings
  def set_pairings(new_pairings=[])
    self.transaction do
      self.pairings.destroy_all
      new_pairings.each do |pair|
        # AR will rollback when an exception is thrown
        self.pairings.create! pair
      end
    end
    return self.pairings
  end

  def self.build(options)
    p = self.new(options)
    unless p.name
      p.name = Faker::Food.ingredient
    end
    return p
  end

  def score
    sum = 0
    self.pairings.each do |pairing|
      ranking = Ranking.find_by(student_id: pairing.student_id, company_id: pairing.company_id)
      if ranking
        sum += ranking.student_preference * ranking.interview_result
      end
    end
    return sum
  end

  def solve
    puts "About to generate solution for pairing #{self.name} for classroom #{self.classroom.name} with #{self.classroom.students.count} students and #{self.classroom.companies.count} companies"

    start_time = Time.now
    solver = Solver.new(self.classroom)
    pairings = solver.solve
    end_time = Time.now

    self.transaction do
      # Clear out any existing pairings
      # TODO DPR: handle solving the remainder of a pairing
      self.pairings.destroy_all

      # Add all the generated pairings to this placement
      pairings.each do |pair|
        pair.placement = self
        pair.save!
      end
    end

    puts "Generated #{pairings.length} pairings with total score #{self.score} in #{Time.now - start_time} seconds, #{solver.iterations} iterations"
  end

  def duplicate(owner)
    copy = Placement.build(classroom_id: self.classroom_id, owner: owner)
    Placement.transaction do
      copy.save!

      self.pairings.each do |pairing|
        pair_copy = pairing.dup
        pair_copy.placement = copy
        pair_copy.save!
      end
    end
    return copy
  end
end
