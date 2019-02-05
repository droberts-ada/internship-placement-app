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

  describe 'to_csv' do
    it 'generates a CSV for feedbacks' do
      feedback_sets = [
        [interview_feedbacks(:ada_space)],
        InterviewFeedback.all,
        InterviewFeedback.where('id < 0'),
      ]

      feedback_sets.each do |feedbacks|
        serializer = InterviewFeedbackSerializer.new(feedbacks)

        feedback_csv = serializer.to_csv

        rows = CSV.parse(feedback_csv)
        expect(rows.length).must_equal feedbacks.length + 1
      end
    end

    # TODO: Test the CSV data more thoroughly
    # the fact that the implementation code is so simple makes this seem redundant
  end
end
