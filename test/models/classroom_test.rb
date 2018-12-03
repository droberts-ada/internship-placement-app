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

  describe '#setup_from_interviews!' do
    def csv(name)
      path = File.join fixture_path, 'files', "#{name}.csv"
      CSV.parse(File.open(path).read)
    end

    let(:interviews) { csv(:interviews_good) }

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
