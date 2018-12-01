require 'test_helper'

describe Interview do
  describe 'validations' do
    let(:interview) { interviews(:ada_space) }

    it 'is valid' do
      expect(interview).must_be :valid?
    end

    it 'is not valid without an associated student' do
      interview.student = nil
      expect(interview).wont_be :valid?
    end

    it 'is not valid without an associated company' do
      interview.company = nil
      expect(interview).wont_be :valid?
    end

    it 'is not valid if this student,company interview exists already' do
      second = Interview.new(interview.attributes)

      expect(second).wont_be :valid?
    end

    it 'is not valid unless scheduled in the future' do
      interview.scheduled_at = nil
      expect(interview).wont_be :valid?

      interview.scheduled_at = Date.yesterday.at_noon
      expect(interview).wont_be :valid?

      interview.scheduled_at = Time.now
      expect(interview).wont_be :valid?
    end
  end
end