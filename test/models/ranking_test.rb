require 'test_helper'

describe Ranking do
  def create_ranking(ranking_data)
    interview = Interview.create!(student: ranking_data[:student],
                                  company: ranking_data[:company],
                                  scheduled_at: Time.now + 1.day)

    return Ranking.create(interview: interview,
                          student_preference: ranking_data[:student_preference])
  end

  describe 'validations' do
    it "Create ranking with student and company" do
      interview_data = {
        student: students(:no_company),
        company: companies(:no_students),
        scheduled_at: Time.now + 2.days
      }

      interview = Interview.create!(interview_data)

      interview_feedback_data = {
        interview: interview,
        interview_result: 5,
        result_explanation: "Good!",
        interviewer_name: "Interviewer"
      }

      InterviewFeedback.create!(interview_feedback_data)

      ranking_data = {
        interview: interview,
        student_preference: 3,
      }

      # create! throws on failure
      Ranking.create!(ranking_data)
    end

    it "Cannot create ranking without interview" do
      ranking_data = {
        interview: nil,
        student_preference: 3,
      }
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview
    end

    it "Cannot create ranking without student_preference" do
      ranking_data = {
        student: students(:no_company),
        company: companies(:no_students),
        interview_result: 5
      }
      r = create_ranking(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference
    end

    it "An interview can have only one ranking" do
      template = Ranking.first
      r = Ranking.new(interview: template.interview, student_preference: 1)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview
    end

    it "Student ranking must be positive integer" do
      student = Student.create!(name: "Alice", classroom: Classroom.first)
      company = Company.create!(name: "Wonderland", classroom: Classroom.first, slots: 1)
      interview = Interview.create!(student: student,
                                    company: company,
                                    scheduled_at: Time.now + 7.days)

      # Not integer
      r = Ranking.create(interview: interview, student_preference: 10.6)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference

      # Not number
      r = Ranking.create(interview: interview, student_preference: "down the rabbit hole")
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference

      # Under
      r = Ranking.create(interview: interview, student_preference: 0)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference
    end
  end

  describe '#interview' do
    it 'returns the interview for this ranking' do
      ranking = rankings(:ada_space)

      expect(ranking.interview).must_equal interviews(:ada_space)
    end
  end

  describe '#interview_result_reason' do
    it 'returns the interview feedback\'s result explanation' do
      ranking = rankings(:ada_space)

      expect(ranking.interview_result_reason).must_equal 'This candidate was great!'
    end

    it 'returns the combined result of multiple feedbacks' do
      ranking = rankings(:ada_space)
      reason_orig = ranking.interview_result_reason

      reason_new = 'This candidate was okay.'
      interview = ranking.interview
      interview.interview_feedbacks.create!(
        interviewer_name: 'Interviewer Two',
        interview_result: 3,
        result_explanation: reason_new,
        feedback_technical: '',
        feedback_nontechnical: '',
      )

      expect(ranking.interview_result_reason).must_equal "#{reason_orig}\n#{reason_new}"
    end

    it 'returns nil if there are no interviews or feedback' do
      ranking = rankings(:no_feedback_jane_freedom)
      expect(ranking.interview_result_reason).must_be_nil

      ranking = rankings(:no_feedback_jane_stark)
      expect(ranking.interview_result_reason).must_be_nil
    end
  end
end
