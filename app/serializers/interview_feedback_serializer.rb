class InterviewFeedbackSerializer
  def initialize(feedback)
    raise ArgumentError.new('Interview feedback is required') unless feedback

    @feedback = feedback
  end

  def to_csv
    CSV.generate do |csv|
      csv << columns(nil).keys

      @feedback.each do |feedback|
        csv << columns(feedback).values.map { |col| col.call }
      end
    end
  end

  private

  def columns(f) {
    'Student Class' => -> { f.interview.student.classroom.name },
    'Student Name' => -> { f.interview.student.name },
    'Company Name' => -> { f.interview.company.name },
    'Interviewer Name' => -> { f.interviewer_name },
    'Interview Result' => -> { f.interview_result },
    'Explanation of Feedback Result (for Staff)' => -> { f.result_explanation },
    'Technical Feedback for Student' => -> { f.feedback_technical },
    'Non-technical Feedback for Student' => -> { f.feedback_nontechnical },
  } end
end
