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

  describe 'scopes' do
    describe 'has_feedback' do
      it 'returns all interviews with at least one feedback associated' do
        has_feedback = Interview.all.has_feedback

        expect(has_feedback).must_include interviews(:ada_space)
        expect(has_feedback).wont_include interviews(:grace_freedom)

        has_feedback.each do |interview|
          expect(interview.interview_feedbacks).wont_be :empty?
        end
      end
    end
  end

  describe '#has_feedback?' do
    it 'returns true when the interview has feedback' do
      i = interviews(:ada_space)
      # Sanity check
      expect(InterviewFeedback.where(interview: i).count).must_be :>, 0

      expect(i.has_feedback?).must_equal true
    end

    it 'returns false when the interview does not have feedback' do
      i = interviews(:grace_freedom)
      # Sanity check
      expect(InterviewFeedback.where(interview: i).count).must_equal 0

      expect(i.has_feedback?).must_equal false
    end
  end

  describe '#interview_result' do
    it 'returns the integer average of results from all interview feedbacks' do
      i = interviews(:ada_space)
      results = InterviewFeedback.where(interview: i).map(&:interview_result)
      # Sanity check
      expect(results.count).must_be :>, 0
      results_avg = results.sum.to_f / results.count
      expect(results_avg).must_equal results_avg.to_i # Start with integral average

      # We should get the average from existing feedback
      expect(i.interview_result).must_equal results_avg.round

      # Find a feedback result that ensures a fractional average
      result = 1
      result += 1 if ((results.sum.to_f + 1) / (results.count + 1)).denominator == 1
      new_avg = (results.sum.to_f + result) / (results.count + 1)

      InterviewFeedback.create!(
        interview_feedbacks(:ada_space)
          .attributes
          .merge({ id: nil, interview_result: result })
      )

      # We should also get the integer average with new feedback added
      i.reload
      expect(i.interview_result).must_equal new_avg.round
    end

    it 'returns nil when there are no interview feedbacks' do
      i = interviews(:grace_freedom)
      # Sanity check
      expect(InterviewFeedback.where(interview: i).count).must_equal 0

      expect(i.interview_result).must_be_nil
    end
  end
end
