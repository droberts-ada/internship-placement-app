require 'spreadsheet'

class StudentPreferenceSpreadsheet < Spreadsheet
  EXPECTED_HEADERS = ["Timestamp", "Student Name", "Positive Feelings", "Neutral Feelings", "Negative Feelings"].sort.freeze
  FEELING_POINTS = {
    "Positive Feelings" => 5,
    "Neutral Feelings" => 4,
    "Negative Feelings" => 2
  }.freeze

  def populate
    raw_data = self.get_data("Form Responses 1!A:H")

    # Split out headers and rows
    headers = raw_data[0]
    raw_data = raw_data[1..-1]

    if headers.uniq.sort != EXPECTED_HEADERS
      raise SpreadsheetError.new("Student rank headers dont match, expected #{EXPECTED_HEADERS} (repeats OK), got #{headers}")
    end

    # Hash of form "Student Name" => { "company name" => score }
    parsed_data = {}
    duplicate_names = []

    # Parse the rows
    raw_data.each do |row|
      preferences = {}
      name = nil
      headers.each_with_index do |key, i|
        if row[i].nil? or row[i].empty? or key == "Timestamp"
          next

        elsif FEELING_POINTS.include? key
          preferences[row[i]] = FEELING_POINTS[key]

        elsif key == "Student Name"
          name = row[i]

        else
          raise SpreadsheetError("Unexpected column #{key} in student preference spreadsheet")
        end
      end

      if name.nil?
        raise SpreadsheetError("In student preference spreadsheet, encountered row with no student name")
      end

      if parsed_data.include? name
        # This will be an error, but we'll want to collect all
        # the duplicates so we won't raise yet
        duplicate_names << name
      end

      parsed_data[name] = preferences
    end

    if duplicate_names.length > 0
      raise SpreadsheetError.new("Student preference spreadsheet contains duplicate rows for students #{duplicate_names}")
    end

    return parsed_data
  end
end
