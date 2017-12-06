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
