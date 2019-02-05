require 'test_helper'
require 'csv'

describe InterviewFeedbackSerializer do
  describe 'constructor' do
    it 'raises ArgumentError without feedback' do
      expect {
        InterviewFeedbackSerializer.new(nil)
      }.must_raise ArgumentError
    end
  end
end
