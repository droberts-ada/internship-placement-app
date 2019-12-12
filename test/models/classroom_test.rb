require 'test_helper'
require 'csv'

describe Classroom do
  let(:classroom) { classrooms(:jets) }

  describe 'validations' do
    it 'can be valid' do
      expect(classroom).must_be :valid?
    end

    it 'is not valid with no name' do
      [nil, '', '   '].each do |name|
        classroom.name = name
        expect(classroom).wont_be :valid?
      end
    end
  end

  describe "companies_with_open_interviews" do
    it "Returns only open interviews" do
      none = Classroom.create!(name: "None Outstanding", creator: User.first)

      # Create 10
      interviews = (0...10).map do |i|
        company = Company.create!(
          name: "Company #{i}",
          classroom: none,
          slots: 1
        )
        Interview.create!(
          company: company,
          student: Student.first,
          scheduled_at: Time.now + 1.day
        )
      end

      # Complete 10
      interviews.each_with_index do |interview, i|
        InterviewFeedback.create!(
          interview: interview,
          interviewer_name: "Person #{i}",
          interview_result:  i % 5 + 1,
          result_explanation: "They were very #{i % 5 + 1}"
        )
      end

      expect(none.companies_with_open_interviews.length).must_equal 0

      some = Classroom.create!(name: "Some Outstanding", creator: User.first)

      # Create 10
      interviews = (0...10).map do |i|
        company = Company.create!(
          name: "Company #{i}",
          classroom: some,
          slots: 1
        )
        Interview.create!(
          company: company,
          student: Student.first,
          scheduled_at: Time.now + 1.day
        )
      end

      # Complete 3
      interviews.take(3).each_with_index do |interview, i|
        InterviewFeedback.create!(
          interview: interview,
          interviewer_name: "Person #{i}",
          interview_result:  i % 5 + 1,
          result_explanation: "They were very #{i % 5 + 1}"
        )
      end

      expect(some.companies_with_open_interviews.length).must_equal 7

      all = Classroom.create!(name: "All Outstanding", creator: User.first)

      # Create 10
      interviews = (0...10).map do |i|
        company = Company.create!(
          name: "Company #{i}",
          classroom: all,
          slots: 1
        )
        Interview.create!(
          company: company,
          student: Student.first,
          scheduled_at: Time.now + 1.day
        )
      end

      # Complete 0

      expect(all.companies_with_open_interviews.length).must_equal 10
    end
  end

  describe '#setup_from_interviews!' do
    def csv(name)
      path = File.join fixture_path, 'files', "#{name}.csv"
      CSV.parse(File.open(path).read)
    end

    let(:interviews) { csv(:interviews_good) }

    it 'creates each company with correct slots count' do
      interviews_per_slot = classroom.interviews_per_slot

      company_interviews = {
        'FizzBuzz Inc' => 4,
        'Websites-R-Us' => 4,
      }

      expect {
        classroom.setup_from_interviews!(interviews)

        company_interviews.each do |name, interviews|
          company = Company.find_by(name: name)
          expect(company).wont_equal nil

          expect(company.slots).must_equal interviews / interviews_per_slot
        end
      }.must_change -> { Company.count }, company_interviews.count
    end

    it 'creates each student' do
      students_count = 4

      expect {
        classroom.setup_from_interviews!(interviews)
      }.must_change -> { Student.count }, students_count
    end

    it 'creates all listed interviews' do
      expect {
        classroom.setup_from_interviews!(interviews)
      }.must_change -> { Interview.count }, interviews.count
    end
  end

  describe "current" do
    it "only returns current classrooms" do
      included = [Classroom.create!(creator: User.first,
                                    name: "today",
                                    created_at: Time.now),
                  Classroom.create!(creator: User.first,
                                    name: "six months ago",
                                    created_at: Time.now - 180.days),
                  Classroom.create!(creator: User.first,
                                    name: "269 days ago",
                                    created_at: Time.now - 269.days)]
      excluded = Classroom.create!(creator: User.first,
                                   name: "270 days ago",
                                   created_at: Time.now - 270.days)

      included.each do |room|
        expect(Classroom.current).must_include(room)
      end

      expect(Classroom.current).wont_include(excluded)
    end
  end
end
