require 'test_helper'

describe Solver do
  let (:classroom) { Classroom.find_by(name: "solver_test") }
  let (:solver) { Solver.new(classroom) }

  describe '#initialize' do
    it "rejects classrooms with mismatched students and companies" do
      Classroom.transaction do
        classroom = Classroom.create!(name: 'solver scale test', creator: User.first)
        23.times do |i|
          classroom.students.create!(name: "scale test student #{i}")
        end

        # The extra [1] between the 3 and the 2s is important
        # for making student assignments line up later
        company_slots = [3] + [1] + ([2] * 5) + ([1] * 10)
        company_slots.sum.must_equal 24
        company_slots.each_with_index do |s, i|
          classroom.companies.create!(name: "scale test company #{i}", slots: s)
        end

        expect { Solver.new(classroom) }.must_raise ArgumentError
      end
    end

    it "builds a matrix of correct size" do
      expected_rows = classroom.students.count
      solver.matrix.row_count.must_equal expected_rows

      expected_cols = classroom.companies.reduce(0) do |sum, co|
        sum + co.slots
      end
      solver.matrix.column_count.must_equal expected_cols
    end

    it "builds a matrix with correct values" do
      solver.matrix.each_with_index do |value, row, col|
        rank = classroom.rankings.find_by(
        student: solver.students[row],
        company: solver.companies[col]
        )
        if rank.nil?
          value.must_equal Float::INFINITY
        else
          value.must_be :>=, 0
          value.must_be :<=, 24
        end
      end

      puts
      puts solver.matrix
      puts
    end

    it "applies the initial reduction" do
      solver.matrix.row_count.times do |r|
        solver.matrix.row(r).min.must_equal 0
      end
      solver.matrix.column_count.times do |c|
        solver.matrix.column(c).min.must_equal 0
      end
    end
  end

  describe "#solve" do
    def check_pairings(pairings, classroom)
      pairings.length.must_equal classroom.students.length

      # Check for duplicates
      students = {}
      companies = Hash.new([])
      pairings.each do |pair|
        pair.must_be_kind_of Pairing
        classroom.students.must_include pair.student
        classroom.companies.must_include pair.company

        students.wont_include pair.student.name
        students[pair.student.name] = pair.company.name

        companies[pair.company.name].wont_include pair.student.name
        companies[pair.company.name] << pair.student.name
      end
      companies.each do |name, students|
        company = classroom.companies.find_by(name: name)
        students.length.must_equal company.slots
      end

      # TODO DPR: figure out a way to check that the set of
      # pairings is optimal / stable / something
    end

    it "produces an array" do
      pairings = solver.solve
      check_pairings(pairings, classroom)
    end

    it "produces an error on an unsolvable classroom" do
      classroom.students.each do |student|
        student.rankings.destroy_all
      end

      # students 1, 2 and 3 interviewed with company 1
      Ranking.create!(student: Student.find_by(name: :st_stu_one), company: Company.find_by(name: :st_co_one), student_preference: 5, interview_result: 5)
      Ranking.create!(student: Student.find_by(name: :st_stu_two), company: Company.find_by(name: :st_co_one), student_preference: 5, interview_result: 5)
      Ranking.create!(student: Student.find_by(name: :st_stu_three), company: Company.find_by(name: :st_co_one), student_preference: 5, interview_result: 5)

      # student 4 interviewed with companies 2 and 3
      Ranking.create!(student: Student.find_by(name: :st_stu_four), company: Company.find_by(name: :st_co_two), student_preference: 5, interview_result: 5)
      Ranking.create!(student: Student.find_by(name: :st_stu_four), company: Company.find_by(name: :st_co_three), student_preference: 5, interview_result: 5)

      solver = Solver.new(classroom)
      proc {
        solver.solve
      }.must_raise SolutionError
    end


    SCALE = 24
    INTERVIEWS_PER_SLOT = 6
    def build_classroom(rng)
      # Build students and companies
      classroom = nil
      Classroom.transaction do
        classroom = Classroom.create!(name: 'solver scale test', creator: User.first)
        SCALE.times do |i|
          classroom.students.create!(name: "scale test student #{i}")
        end

        # The extra [1] between the 3 and the 2s is important
        # for making student assignments line up later
        company_slots = [3] + [1] + ([2] * 5) + ([1] * 10)
        company_slots.sum.must_equal SCALE
        company_slots.each_with_index do |s, i|
          classroom.companies.create!(name: "scale test company #{i}", slots: s)
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
          students.length.must_equal interview_count

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
        available_students.must_be_empty
      end

      return classroom
    end

    def solve_classroom(classroom)
      # We're set up - time to build and run the solver
      start_time = Time.now
      solver = Solver.new(classroom)
      pairings = solver.solve
      total_time = Time.now - start_time

      check_pairings(pairings, classroom)

      return total_time, solver.iterations
    end

    it "Can handle a full-scale classroom" do
      # Report the RNG seed for repeatability
      seed = Random.new_seed
      puts
      puts "In full-scale test, using seed #{seed}"
      rng = Random.new(seed)

      classroom = build_classroom(rng)
      total_time, iterations = solve_classroom(classroom)
      puts "Converged in #{total_time} seconds, #{iterations} iterations"
    end

    it "Always converges" do
      skip "takes a long-ass time"
      # Haven't looked into actually proving this (it probably doesn't), so for
      # now we'll just try it 100 times and see what we get

      seed = Random.new_seed
      puts
      puts "In many iteration test, using seed #{seed}"
      rng = Random.new(seed)

      times = []
      iterations = []
      failures = 0
      start_time = Time.now
      100.times do |i|
        begin
          classroom = build_classroom(rng)
          run_time, run_iterations = solve_classroom(classroom)
          puts "Run #{i} finished in #{run_time} seconds, #{run_iterations} iterations"
          times << run_time
          iterations << run_iterations
        rescue SolutionError
          # TODO: give some information about what the arrangement looked
          # like so we can come up with a characterization of these
          # pathological scenarios
          puts "Found a case that failed to converge!"
          failures += 1
        end
      end

      # puts times
      # puts iterations

      average_time = 1.0 * times.sum / times.length
      average_iters = 1.0 * iterations.sum / iterations.length

      puts "Finished 100 runs in #{Time.now - start_time} seconds"
      puts "Avg run time: #{average_time}"
      puts "Avg iterations: #{average_iters}"
      puts "Failure rate: #{failures}"
    end
  end
end
