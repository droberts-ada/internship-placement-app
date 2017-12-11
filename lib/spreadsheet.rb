require 'access_token'

SheetsService = Google::Apis::SheetsV4::SheetsService
ValueRange = Google::Apis::SheetsV4::ValueRange

class Spreadsheet
  class SpreadsheetError < StandardError; end

  def initialize(spreadsheet_id, user)
    @spreadsheet_id = spreadsheet_id
    @user = user
    self.populate
  end

  def get_data(range)
    google_sheets = SheetsService.new
    google_sheets.authorization = AccessToken.new(@user.oauth_token)
    response = google_sheets.get_spreadsheet_values(@spreadsheet_id, range)
    return response.values
  end

  def self.export_data(headers, rows, user)
    if headers.count < 1
      raise ArgumentError.new("Exporting data to Google Sheets requires at least one column")
    end

    if rows.any? { |r| r.count > headers.count }
      raise ArgumentError.new("Exporting data to Google Sheets requires a header for each column")
    end

    google_sheets = SheetsService.new
    google_sheets.authorization = AccessToken.new(user.oauth_token)

    sheet = google_sheets.create_spreadsheet do |_, error|
      raise error if error
    end

    # Determine the range we need to update
    # Add one to row count to allow for headers row
    # Note: Doesn't work when columns need to extend beyond Z (into AA, AB, etc.)
    range_start = 'A1'
    range_end = ('A'..'Z').to_a[headers.count - 1] + (rows.count + 1).to_s
    range = "#{range_start}:#{range_end}"

    # Create the ValueRange to represent our exported data
    # First ensure that we have data values for every cell in the range ('' means empty cell)
    values = [headers] + rows.map { |r| r.fill('', (r.count)..(headers.count - 1)) }
    value_range = ValueRange.new(
      major_dimension: 'ROWS',
      range: range,
      values: values
    )

    google_sheets.update_spreadsheet_value(sheet.spreadsheet_id, range, value_range, value_input_option: "USER_ENTERED") do |_, error|
      raise error if error
    end

    return sheet.spreadsheet_url
  end
end
