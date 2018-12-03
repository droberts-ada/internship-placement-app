require 'test_helper'

describe Student do
  let(:student) { students(:ada) }

  describe 'associations' do
    it 'belongs to a classroom' do
      class_assoc = Student.reflect_on_association(:classroom)
      expect(class_assoc.macro).must_equal :belongs_to
    end

    it 'has many rankings' do
      rankings_assoc = Student.reflect_on_association(:rankings)
      expect(rankings_assoc.macro).must_equal :has_many
    end

    it 'has many companies' do
      companies_assoc = Student.reflect_on_association(:companies)
      expect(companies_assoc.macro).must_equal :has_many
    end

    it 'has many interviews' do
      interviews_assoc = Student.reflect_on_association(:interviews)
      expect(interviews_assoc.macro).must_equal :has_many
    end
  end

  describe 'validations' do
    it 'can be valid' do
      expect(student).must_be :valid?
    end

    it 'is not valid without a classroom' do
      student.classroom = nil
      expect(student).wont_be :valid?
    end
  end
end
