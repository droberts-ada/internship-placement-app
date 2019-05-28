class InterviewFeedbackSerializer
  HEADERS = [
    'Student Class',
    'Student Name',
    'Company Name',
    'Interviewer Name',
    'Interview Result',
    'Explanation of Feedback Result (for Staff)',
    'Technical Feedback for Student',
    'Non-technical Feedback for Student',
  ]

  def initialize(feedback)
    raise ArgumentError.new('Interview feedback is required') unless feedback

    @feedback = feedback
  end

  def to_csv
    CSV.generate do |csv|
      csv << HEADERS

      @feedback.each do |feedback|
        csv << row(feedback)
      end
    end
  end

  private

  def row(f)
    [
      f.interview.student.classroom.name,
      f.interview.student.name,
      f.interview.company.name,
      f.interviewer_name,
      f.interview_result,
      f.result_explanation,
      f.feedback_technical,
      f.feedback_nontechnical
    ]
  end
end
