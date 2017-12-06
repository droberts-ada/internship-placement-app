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
