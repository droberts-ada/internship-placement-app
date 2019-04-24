require 'test_helper'

describe Ranking do
  describe 'validations' do
    it "Create ranking with student and company" do
      ranking_data = {
        student: students(:no_company),
        company: companies(:no_students),
        student_preference: 3,
        interview_result: 5
      }
      # create! throws on failure
      r = Ranking.create!(ranking_data)
    end

    it "Cannot create ranking without student" do
      ranking_data = {
        company: companies(:no_students),
        student_preference: 3,
        interview_result: 5
      }
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :student
    end

    it "Cannot create ranking without company" do
      ranking_data = {
        student: students(:no_company),
        student_preference: 3,
        interview_result: 5
      }
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :company
    end

    it "Cannot create ranking without student_preference" do
      ranking_data = {
        student: students(:no_company),
        company: companies(:no_students),
        interview_result: 5
      }
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference
    end

    it "Cannot create ranking without interview_result" do
      ranking_data = {
        student: students(:no_company),
        company: companies(:no_students),
        student_preference: 3
      }
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview_result
    end

    it "A student-company pair can have only one ranking" do
      template = Ranking.first
      r = Ranking.new(student: template.student,
                      company: template.company);
      assert_not r.valid?
      assert_includes r.errors.messages, :student
    end

    it "Student ranking must be positive integer" do
      ranking_data = {
        student: students(:no_company),
        company: companies(:no_students),
        interview_result: 4
      }

      # Not integer
      ranking_data[:student_preference] = 3.3
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference

      # Not number
      ranking_data[:student_preference] = 'foo bar'
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference

      # Under
      ranking_data[:student_preference] = 0
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :student_preference
    end

    it "Interview result must be integer, 0 < i <= 5" do
      ranking_data = {
        student: students(:no_company),
        company: companies(:no_students),
        student_preference: 4
      }

      # Not integer
      ranking_data[:interview_result] = 3.3
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview_result

      # Not number
      ranking_data[:interview_result] = 'foo bar'
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview_result

      # Under
      ranking_data[:interview_result] = 0
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview_result

      # Over
      ranking_data[:interview_result] = 6
      r = Ranking.create(ranking_data)
      assert_not r.valid?
      assert_includes r.errors.messages, :interview_result
    end
  end

  describe '#score' do
    it 'returns the product of the student preference and interview result' do
      ranking = rankings(:ada_space)
      student_preference = ranking.student_preference
      interview_result = ranking.interview_result

      expect(ranking.score).must_equal student_preference * interview_result
    end

    it 'updates the score when student_preference is updated' do
      ranking = rankings(:ada_space)
      interview_result = ranking.interview_result
      original_score = ranking.score

      ranking.student_preference += 1

      expect(ranking.score).must_equal original_score + interview_result
    end

    it 'updates the score when student_preference is updated' do
      ranking = rankings(:ada_space)
      student_preference = ranking.student_preference
      original_score = ranking.score

      ranking.interview_result += 1

      expect(ranking.score).must_equal original_score + student_preference
    end
  end

  describe '#interview' do
    it 'returns the interview for this ranking' do
      ranking = rankings(:ada_space)

      expect(ranking.interview).must_equal interviews(:ada_space)
    end

    it 'returns nil if there is no interview for this ranking' do
      ranking = rankings(:grace_stark)

      expect(ranking.interview).must_be_nil
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
      interview = Interview.find_by(student: ranking.student, company: ranking.company)
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
      ranking = rankings(:grace_freedom)
      expect(ranking.interview_result_reason).must_be_nil

      ranking = rankings(:grace_stark)
      expect(ranking.interview_result_reason).must_be_nil
    end
  end
end
