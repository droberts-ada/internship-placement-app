require 'test_helper'

describe Interview do
  describe 'associations' do
    it 'has many interview feedbacks' do
      feedback_assoc = Interview.reflect_on_association(:interview_feedbacks)
      expect(feedback_assoc.macro).must_equal :has_many
    end
  end

  describe 'validations' do
    let(:interview) { interviews(:ada_space) }

    it 'can be valid' do
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

    it 'must be scheduled in the future, when creating new interviews' do
      [nil, Date.yesterday.at_noon, Time.now].each do |time|
        attrs = interview.attributes.merge(scheduled_at: time)

        old_interview = Interview.new(attrs)
        expect(old_interview).wont_be :valid?
      end
    end
  end
end
