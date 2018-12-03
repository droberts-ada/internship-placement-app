require 'test_helper'

describe InterviewFeedback do
  describe 'associations' do
    it 'belongs to an Interview' do
      interview_assoc = InterviewFeedback.reflect_on_association(:interview)
      expect(interview_assoc.macro).must_equal :belongs_to
    end
  end

  describe 'validations' do
    let(:feedback) { interview_feedbacks(:ada_space) }

    it 'can be valid' do
      expect(feedback).must_be :valid?
    end

    it 'is not valid without an interview' do
      feedback.interview = nil

      expect(feedback).wont_be :valid?
    end

    it 'is is not valid without an interviewer name' do
      feedback.interviewer_name = ''

      expect(feedback).wont_be :valid?
    end

    it 'is is not valid without an interview result' do
      feedback.interview_result = nil

      expect(feedback).wont_be :valid?
    end

    it 'is is not valid without a result explanation' do
      feedback.result_explanation = ''

      expect(feedback).wont_be :valid?
    end

    it 'validates interview result to be 1-5' do
      [nil, 0, -1, 6].each do |bad_result|
        feedback.interview_result = bad_result

        expect(feedback).wont_be :valid?
      end
    end
  end

  describe '.create_from_form_response' do
    def response(name, interview_fixture)
      path = File.join fixture_path, %w(files typeform), "#{name}.json"
      request = JSON.load(File.open(path))
      event = Typeform::WebhookEvent.from_params(request)

      interview = interviews(interview_fixture)
      event.data[:hidden][:interview_id] = interview.id

      Typeform::FormResponse.from_webhook_event(event)
    end

    let(:response_good) { response(:webhook_req_good, :ada_space) }

    it 'creates a new InterviewFeedback model' do
      expect {
        InterviewFeedback.create_from_form_response(response_good)
      }.must_change -> { InterviewFeedback.count }, 1
    end

    it 'raises RecordNotFound when interview id is not valid' do
      [nil, 0, -1, Interview.pluck(:id).max + 1].each do |interview_id|
        expect {
          response_good.hidden[:interview_id] = interview_id
          InterviewFeedback.create_from_form_response(response_good)
        }.must_raise ActiveRecord::RecordNotFound
      end
    end

    it 'is associates feedback with the correct interview' do
      feedback = InterviewFeedback.create_from_form_response(response_good)

      expect(feedback.interview).must_equal interviews(:ada_space)
    end

    describe 'feedback data' do
      let(:feedback) do
        InterviewFeedback.create_from_form_response(response_good)
      end

      it 'sets the interviewer name' do
        # Hard coded for "webhook_req_good"
        expect(feedback.interviewer_name).must_equal 'Irene Interviewer'
      end

      it 'sets the interview result' do
        # Hard coded for "webhook_req_good"
        expect(feedback.interview_result).must_equal 4
      end

      it 'sets the result explanation' do
        # Hard coded for "webhook_req_good"
        expect(feedback.result_explanation).must_equal 'Explanation of Feedback Summary'
      end

      it 'sets the technical feedback' do
        # Hard coded for "webhook_req_good"
        expect(feedback.feedback_technical).must_equal 'Technical Feedback for Student'
      end

      it 'sets the non-technical feedback' do
        # Hard coded for "webhook_req_good"
        expect(feedback.feedback_nontechnical).must_equal 'Non-technical Feedback for Student'
      end
    end
  end
end
