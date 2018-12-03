require 'test_helper'

describe Company do
  let(:company) { companies(:space_labs) }

  describe 'associations' do
    it 'belongs to a classroom' do
      class_assoc = Company.reflect_on_association(:classroom)
      expect(class_assoc.macro).must_equal :belongs_to
    end

    it 'has many rankings' do
      rankings_assoc = Company.reflect_on_association(:rankings)
      expect(rankings_assoc.macro).must_equal :has_many
    end

    it 'has many students' do
      students_assoc = Company.reflect_on_association(:students)
      expect(students_assoc.macro).must_equal :has_many
    end

    it 'has many interviews' do
      interviews_assoc = Company.reflect_on_association(:interviews)
      expect(interviews_assoc.macro).must_equal :has_many
    end
  end

  describe 'validations' do
    it 'can be valid' do
      expect(company).must_be :valid?
    end

    it 'is not valid without a classroom' do
      company.classroom = nil
      expect(company).wont_be :valid?
    end
  end
end
