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
    def params(name)
      path = Rails.root.join *(%w(test data typeform)+["#{name}.json"])
      JSON.load(File.open(path))
    end

    let(:params_good) { params(:webhook_req_good) }

    it 'returns 200 OK for valid requests' do
      post feedback_interviews_path, params: params_good

      must_respond_with :ok
    end
  end
end
