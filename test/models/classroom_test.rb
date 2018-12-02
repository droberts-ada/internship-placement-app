require 'test_helper'
require 'csv'

describe Classroom do
  describe '#setup_from_interviews!' do
    def csv(name)
      path = Rails.root.join *(%w(test data)+["#{name}.csv"])
      CSV.parse(File.open(path).read)
    end

    let(:interviews) { csv(:interviews) }

    let(:classroom) { classrooms(:jets) }

    it 'creates each company with correct slots count' do
      company_counts = {
        'FizzBuzz Inc' => 4,
        'Websites-R-Us' => 4,
      }

      expect {
        classroom.setup_from_interviews!(interviews)

        company_counts.each do |name, count|
          company = Company.find_by(name: name)
          expect(company).wont_equal nil

          expect(company.slots).must_equal count
        end
      }.must_change -> { Company.count }, company_counts.count
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
end
