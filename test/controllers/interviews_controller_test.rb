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
    def request_with_secret(params)
      query = { typeform_secret: ENV['TYPEFORM_SECRET'] }

      post feedback_interviews_path(query), params: params
    end

    def params(name)
      path = Rails.root.join *(%w(test data typeform)+["#{name}.json"])
      JSON.load(File.open(path))
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
  end
end
