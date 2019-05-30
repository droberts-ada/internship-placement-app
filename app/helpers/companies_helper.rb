module CompaniesHelper
  def format_interview(interview)
    return "#{interview.student.name} on " +
           "#{interview.scheduled_at.strftime("%B %d")} at " +
           "#{interview.scheduled_at.strftime("%l:%M %p")}"
  end
end
