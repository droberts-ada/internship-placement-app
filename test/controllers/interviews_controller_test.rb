require 'test_helper'

describe InterviewsController do
  let(:interview) { interviews(:ada_space) }

  describe 'index' do
    it 'returns 200 OK without logging in' do
      get interviews_path

      must_respond_with :ok
    end
  end

  describe 'show' do
  end
end
