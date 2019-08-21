require 'test_helper'

describe InterviewFeedbacksController do
  let(:required_params) {
    {
      interviewer_name: 'Ada',
      interview_result: 3,
      result_explanation: "Explanation!"
    }.freeze
  }
  let(:all_params) {
    required_params.merge(
      {
        feedback_technical: "Technical Feedback!",
        feedback_nontechnical: "Nontechnical Feedback!"
      }).freeze
  }

  describe 'new' do
    it 'returns SUCCESS without logging in' do
      get new_interview_interview_feedback_path(Interview.first.uuid)

      must_respond_with :success
    end

    it 'returns NOT FOUND if Interview is missing' do
      get new_interview_interview_feedback_path(InterviewFeedback.maximum(:id).next)

      must_respond_with :not_found
    end
  end

  describe 'create' do
    it 'Successfully creates an InterviewFeedback with only required params' do
      interview = Interview.first

      post(interview_interview_feedbacks_path(interview.uuid), params: { interview_feedback: required_params })

      must_respond_with :redirect
      must_redirect_to company_path(interview.company.uuid)

      feedback = InterviewFeedback.last

      expect(feedback.interviewer_name).must_equal required_params[:interviewer_name]
      expect(feedback.interview_result).must_equal required_params[:interview_result]
      expect(feedback.result_explanation).must_equal required_params[:result_explanation]
    end

    it 'Successfully creates an InterviewFeedback with optional params' do
      interview = Interview.first

      post(interview_interview_feedbacks_path(interview.uuid), params: { interview_feedback: all_params })

      must_respond_with :redirect
      must_redirect_to company_path(interview.company.uuid)

      feedback = InterviewFeedback.last

      expect(feedback.interviewer_name).must_equal all_params[:interviewer_name]
      expect(feedback.interview_result).must_equal all_params[:interview_result]
      expect(feedback.result_explanation).must_equal all_params[:result_explanation]
      expect(feedback.feedback_technical).must_equal all_params[:feedback_technical]
      expect(feedback.feedback_nontechnical).must_equal all_params[:feedback_nontechnical]
    end

    it 'Missing required values cause a redirect' do
      params = {
        feedback_technical: "Technical Feedback!",
        feedback_nontechnical: "Nontechnical Feedback!"
      }

      post(interview_interview_feedbacks_path(Interview.first.uuid),
           params: { interview_feedback: params })

      expect(flash[:status]).must_equal :failure

      must_respond_with :redirect
      must_redirect_to company_path(Interview.first.company.uuid)
    end
  end

  describe 'edit' do
    describe 'Edit and update are presently disabled for security reasons' do
      it 'GET must not route' do
        feedback = InterviewFeedback.new(required_params).tap do |f|
          f.interview = Interview.first
        end

        feedback.save!

        expect do
          get edit_interview_interview_feedback_path(feedback.interview.uuid, feedback)
        end.must_raise NoMethodError
      end
    end

    it 'Must return SUCCESS without login' do
      skip

      feedback = InterviewFeedback.new(required_params).tap do |f|
        f.interview = Interview.first
      end

      feedback.save!

      get edit_interview_interview_feedback_path(feedback.interview.uuid, feedback)

      must_respond_with :success
    end

    it 'Must return NOT FOUND if interview feedback is missing' do
      skip

      get edit_interview_interview_feedback_path(Interview.first.uuid, InterviewFeedback.maximum(:id).next)

      must_respond_with :not_found
    end
  end

  describe 'update' do
    describe 'Edit and update are presently disabled for security reasons' do
      it 'PUT must not route' do
        feedback = InterviewFeedback.new(required_params).tap do |f|
          f.interview = Interview.first
        end

        feedback.save!

        expect do
          put(interview_interview_feedback_path(feedback.interview.uuid, feedback),
              params: { interview_feedback: required_params })
        end.must_raise NoMethodError
      end

      it 'PATCH must not route' do
        feedback = InterviewFeedback.new(required_params).tap do |f|
          f.interview = Interview.first
        end

        feedback.save!

        expect do
          patch(interview_interview_feedback_path(feedback.interview.uuid, feedback),
                params: { interview_feedback: required_params })
        end.must_raise NoMethodError
      end
    end

    it 'Must update via PUT without login' do
      skip

      feedback = InterviewFeedback.new(required_params).tap do |f|
        f.interview = Interview.first
      end

      feedback.save!

      params = required_params.merge(
        {
          interviewer_name: "Updated Name"
        })

      put(interview_interview_feedback_path(feedback.interview.uuid, feedback),
          params: { interview_feedback: params })

      must_respond_with :redirect
      must_redirect_to company_path(feedback.interview.company.uuid)

      feedback.reload

      expect(flash[:status]).must_equal :success
      expect(feedback.interviewer_name).must_equal params[:interviewer_name]
    end

    it 'Must update via PATCH without login' do
      skip

      feedback = InterviewFeedback.new(required_params).tap do |f|
        f.interview = Interview.first
      end

      feedback.save!

      params = required_params.merge(
        {
          interviewer_name: "Updated Name"
        })

      patch(interview_interview_feedback_path(feedback.interview.uuid, feedback),
            params: { interview_feedback: params })

      must_respond_with :redirect
      must_redirect_to company_path(feedback.interview.company.uuid)

      feedback.reload

      expect(flash[:status]).must_equal :success
      expect(feedback.interviewer_name).must_equal params[:interviewer_name]
    end

    it 'Must return NOT FOUND if interview feedback is missing' do
      skip

      patch interview_interview_feedback_path(Interview.first.uuid, InterviewFeedback.maximum(:id).next)

      must_respond_with :not_found
    end

    it 'Must fail if given an invalid interview_result' do
      skip

      feedback = InterviewFeedback.new(required_params).tap do |f|
        f.interview = Interview.first
      end

      feedback.save!

      params = required_params.merge(
        {
          interview_result: 42
        })

      patch(interview_interview_feedback_path(feedback.interview.uuid, feedback),
            params: { interview_feedback: params })

      feedback.reload

      expect(flash[:status]).must_equal :failure
      expect(feedback.interview_result).must_equal required_params[:interview_result]
    end
  end
end
