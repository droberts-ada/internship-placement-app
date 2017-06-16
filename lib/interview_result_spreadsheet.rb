require 'spreadsheet'

class InterviewResultSpreadsheet < Spreadsheet
  EXPECTED_HEADERS = ["Timestamp", "Interviewer Name", "Company", "Student Name", "Hiring Decision", "Reason for Hiring Decision"].sort.freeze
  IGNORE_HEADERS = ["Timestamp", "Interviewer Name"].freeze
  RESULT_POINTS = {
    "5" => 5,
    "4" => 4,
    "3" => 3,
    "2" => 2,
    "1" => 1
  }.freeze

  def populate
    raw_data = self.get_data("Form Responses 1!A:F")

    # Split out headers and rows
    headers = raw_data[0]
    raw_data = raw_data[1..-1]

    # Repeats not OK, so no uniq
    if headers.sort != EXPECTED_HEADERS
      raise SpreadsheetError.new("Interview results headers dont match, expected #{EXPECTED_HEADERS}, got #{headers}")
    end

    # Hash of form { "Student Name" => { "Company Name" => { "score" => 3, "reason" => "foo" } } }
    parsed_data = {}

    errors = []

    # Parse the rows
    raw_data.each_with_index do |row, row_index|
      # Turn into a hash fo mo betta programmin!
      datum = {}
      headers.each_with_index do |key, i|
        if row[i].nil? or row[i].empty? or IGNORE_HEADERS.include? key
          next
        else
          datum[key] = row[i]
        end
      end

      name = datum["Student Name"]
      company = datum["Company"]
      result = datum["Hiring Decision"]

      # Do some error handling
      # raw_data has had the headers chopped, and google sheets
      # indexes from 1 not 0, so the row in the error message
      # needs to be modified accordingly
      if name.nil? || name.empty?
        errors << "Row #{row_index+2}: missing Student Name"
      end
      if company.nil? || company.empty?
        errors << "Row #{row_index+2}: missing Company"
      end
      if result.nil? || result.empty?
        errors << "Row #{row_index+2}: missing Hiring Decision"
      elsif !RESULT_POINTS.include? result
        errors << "Row #{row_index+2}: invalid Hiring Decision '#{result}'"
      end

      # Add a new entry for this student if needed
      unless parsed_data.include? name
        parsed_data[name] = {}
      end

      # Check for duplicates
      if parsed_data[name].include? company
        errors << "Row #{row_index+2}: duplicate Student Name / Company pair (#{name} / #{company})"
      end

      parsed_data[name][company] = {
        'score' => RESULT_POINTS[result],
        'reason' => datum["Reason for Hiring Decision"]
      }
    end

    if errors.length > 0
      error_text = "Encountered errors while parsing Interview Results:"
      errors.each do |error|
        error_text += "\n" + error
      end
      raise SpreadsheetError.new(error_text)
    end

    return parsed_data
  end
end
