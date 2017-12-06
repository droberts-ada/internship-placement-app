require 'csv'

CLASSROOM_FILE = 'classrooms.csv'
INTERVIEW_FILE = 'interview-feedback.csv'
PREFERENCE_FILE = 'student-preferences.csv'

PARSED_INTERVIEW_FILE = 'interviews-parsed.csv'
PARSED_PREFERENCE_FILE = 'preferences-parsed.csv'

INTERVIEW_SCORES = {
  "This person could be a great addition to our team" => 5,
  "This person could be successful on our team" => 4,
  "This person may or may not be a good addition on our team" => 3,
  "This person may struggle on our team" => 2,
  "This person is not likely to be successful on our team" => 1
}

#
# Classrooms
#

def classrooms
  @classrooms ||= {}.tap do |classrooms|
    CSV.foreach(CLASSROOM_FILE) do |row|
      classrooms[row[1]] = row[0]
    end
  end
end

#
# Student preferences
#

def preferences
  @preferences ||= {}.tap do |preferences|
    CSV.foreach(PREFERENCE_FILE, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
      student = row[1]

      unless classrooms.include? student
        puts "ERROR: Student #{student} has no assigned classroom"
      end

      classroom = classrooms[student]
      preferences[classroom] ||= {}

      if preferences[classroom].include? student
        puts "WARNING: duplicate preferences for student #{student}. Using the last line."
      end

      raw = Hash[row.headers.zip(row.fields)]

      parsed = preferences[classroom][student] = { name: student, timestamp: raw[:timestamp] }

      parsed[:positive] = raw[:positive_feels_please_check_exactly_3_companies_only_select_companies_you_have_interviewed_at].split(',').map { |str| str.strip }
      parsed[:neutral] = raw[:neutral_feels_please_check_exactly_2_companies_only_select_companies_you_have_interviewed_at].split(',').map { |str| str.strip }
      parsed[:negative] = raw[:with_reservation_please_check_exactly_1_companies_only_select_companies_you_have_interviewed_at].split(',').map { |str| str.strip }
      parsed[:companies] = parsed[:positive] + parsed[:neutral] + parsed[:negative]
      parsed[:companies].sort!
    end
  end
end
