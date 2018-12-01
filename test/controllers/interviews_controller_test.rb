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
end
