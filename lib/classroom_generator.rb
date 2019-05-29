require 'faker'
require 'set'

puts "In generate_classroom.rb"

class ClassroomGenerator
  SCALE = 24
  INTERVIEWS_PER_SLOT = 6
  def self.build_classroom(rng = Random.new)
    # Build students and companies
    classroom = nil
    students = Set.new
    companies = Set.new
    Classroom.transaction do
      classroom = Classroom.create!(name: Faker::Hacker.noun.pluralize, creator: User.first)
      SCALE.times do |i|
        student = Faker::Cat.name
        while students.include?(student) do
          student = Faker::Cat.name
        end
        students.add(student)
        classroom.students.create!(name: student)
      end

      # The extra [1] between the 3 and the 2s is important
      # for making student assignments line up later
      company_slots = [3] + [1] + ([2] * 5) + ([1] * 10)
      if company_slots.sum != SCALE
        raise StandardError.new "AHHHHHHHH"
      end
      company_slots.each_with_index do |s, i|
        company = Faker::Company.name
        while companies.include?(company) do
          company = Faker::Company.name
        end
        companies.add(company)
        classroom.companies.create!(name: company, slots: s)
      end

      # Generate rankings
      # We make six shuffled lists of students and consume them
      # in order, to avoid ending up with a student needing to
      # inteveiw at the same company multiple times at the end
      available_students = 6.times.map do
        classroom.students.to_a.shuffle
      end
      student_tier = []

      classroom.companies.each do |company|
        # puts "\nCompany #{company.name} of #{company_slots.length}"

        # Each company interviews 6 students per slot
        interview_count = company.slots * INTERVIEWS_PER_SLOT
        if student_tier.empty?
          # puts "Begin tier #{available_students.length}"
          student_tier = available_students.pop
        end
        students = student_tier.pop(interview_count)

        # Shouldn't run out of students
        if students.length != interview_count
          puts "Hit the bad state. Remaining students:"
          students.each do |s|
            puts "  #{s.name} with #{s.rankings.count} rankings"
          end
        end
        if students.length != interview_count
          raise StandardError.new "AHHHHHHHH"
        end

        # Build a ranking for this company for each student
        students.each do |student|
          student.rankings.create!(
          company: company,
          student_preference: rng.rand(5)+1,
          interview_result: rng.rand(5)+1
          )
        end
      end

      # We should have exactly exhausted our pool of students
      unless available_students.empty?
        raise StandardError.new "AHHHHHHHH"
      end
    end

    return classroom
  end
end
