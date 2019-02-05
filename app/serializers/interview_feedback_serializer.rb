class InterviewFeedbackSerializer
  def initialize(feedback)
    raise ArgumentError.new('Interview feedback is required') unless feedback
  end
end
