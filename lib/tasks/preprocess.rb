interview_results.each do |classroom, students|
  CSV.open("#{classroom}_#{PARSED_INTERVIEW_FILE}", 'wb') do |csv|
    headers = ["Timestamp", "Interviewer Name", "Company", "Student Name", "Hiring Decision", "Reason for Hiring Decision", "Technical Feedback for Candidate", "Nontechnical Feedback for Candidate"]
    csv << headers

    students.each do |student, results|
      results.each do |company, interview|
        line = [
          interview[:timestamp],
          interview[:interviewer_name],
          company,
          student,
          interview[:numeric_result],
          interview[:explanation_of_feedback_summary],
          interview[:technical_feedback_for_candidate],
          interview[:nontechnical_feedback_for_candidate]
        ]
        # if line.include? nil or line.length != headers.length
        #   puts "ERROR: student #{student} company #{company} is missing some interview result data! Line:"
        #   puts line
        # end
        csv << line
      end
    end
  end
end

preferences.each do |classroom, prefs|
  CSV.open("#{classroom}_#{PARSED_PREFERENCE_FILE}", 'wb') do |csv|
    headers = ["Timestamp", "Student Name", "Positive Feelings", "Positive Feelings", "Positive Feelings", "Neutral Feelings", "Neutral Feelings", "Negative Feelings"]
    csv << headers

    prefs.each do |student, results|
      line = [
        results[:timestamp],
        student
      ] + results[:positive] + results[:neutral] + results[:negative]
      if line.include? nil or line.length != headers.length
        puts "ERROR: student #{student} is missing some preference data! Line:"
        puts line
      end
      csv << line
    end
  end
end
