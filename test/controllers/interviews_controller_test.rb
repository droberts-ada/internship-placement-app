require 'test_helper'

describe InterviewsController do
  describe 'public routes' do
    it 'has a feedback webhook endpoint' do
      endpoint = {
        method: :post,
        path: '/interviews/feedback',
      }

      action = {
        controller: 'interviews',
        action: 'feedback',
      }

      expect(action).must_route_for(endpoint)
    end
  end

  describe 'feedback webhook' do
    let(:interview) { interviews(:ada_space) }

    def request_with_secret(params)
      query = { typeform_secret: ENV['TYPEFORM_SECRET'] }

      post feedback_interviews_path(query), params: params
    end

    def params(name, interview_id=nil)
      path = Rails.root.join *(%w(test data typeform)+["#{name}.json"])
      params = JSON.load(File.open(path))

      interview_id ||= interview.id
      params['form_response']['hidden']['interview_id'] = interview_id.to_s

      params
    end

    let(:params_good) { params(:webhook_req_good) }
    let(:params_bad) { params(:webhook_req_bad) }

    it 'returns 200 OK for valid requests' do
      request_with_secret(params_good)

      must_respond_with :ok
    end

    it 'returns 400 Bad Request for invalid requests' do
      [nil, {}, {event_id: ''}, params_bad].each do |params|
        request_with_secret(params)

        must_respond_with :bad_request
      end
    end

    it 'returns 404 Not Found when typeform secret is not correct' do
      [nil, '', SecureRandom.hex(128)].each do |secret|
        query = {typeform_secret: secret}
        post feedback_interviews_path(query), params: params_good

        must_respond_with :not_found
      end
    end

    it 'returns 404 Not Found when interview does not exist' do
      ['', -1, 0, Interview.pluck(:id).max + 1].each do |bad_id|
        params_no_interview = params(:webhook_req_good, bad_id)

        request_with_secret(params_no_interview)

        must_respond_with :not_found
      end
    end

    it 'returns 400 Bad Request when feedback is incomplete' do
      # WARNING: This assumes that in our hard-coded request data
      # the first answer is to a required question
      params_good['form_response']['answers'].delete_at(0)

      request_with_secret(params_good)

      must_respond_with :bad_request
    end

    it 'creates a new InterviewFeedback' do
      expect {
        request_with_secret(params_good)
      }.must_change -> { InterviewFeedback.count }, 1
    end

    it 'associates feedback with correct interview' do
      expect {
        request_with_secret(params_good)
      }.must_change -> { interview.interview_feedbacks.count }, 1
    end

    it 'returns 204 No Content for test requests' do
      event_id = SecureRandom.hex(32)
      params = {
        event_id: event_id,
        event_type: 'form_response',
        form_response: {
          token: event_id
        }
      }

      request_with_secret(params)

      must_respond_with :no_content
    end
  end
end
