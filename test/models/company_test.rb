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

    it 'is not valid without a name' do
      [nil, '', " \t "].each do |name|
        company.name = name
        expect(company).wont_be :valid?
      end
    end

    it 'is only valid with a positive slots count' do
      [nil, -1, 0].each do |slots|
        company.slots = slots
        expect(company).wont_be :valid?
      end
    end
  end

  describe '#interviews_complete?' do
    it 'returns true when all associated interviews are complete' do
      company = companies(:space_labs)
      # Sanity check
      company.interviews.each do |interview|
        expect(interview.interview_feedbacks).wont_be :empty?
      end

      expect(company.interviews_complete?).must_equal true
    end

    it 'returns false when not all associated interviews are complete' do
      company = companies(:freedom_inc)

      # Sanity check
      all_completed = true
      company.interviews.each do |interview|
        all_completed &&= interview.interview_feedbacks.present?
      end
      expect(all_completed).must_equal false

      expect(company.interviews_complete?).must_equal false
    end
  end
end
