require 'access_token'

class Spreadsheet
  class SpreadsheetError < StandardError; end

  def initialize(spreadsheet_id, user)
    @spreadsheet_id = spreadsheet_id
    @user = user
    self.populate
  end

  def get_data(range)
    google_sheets = Google::Apis::SheetsV4::SheetsService.new
    google_sheets.authorization = AccessToken.new(@user.oauth_token)
    response = google_sheets.get_spreadsheet_values(@spreadsheet_id, range)
    return response.values
  end
end
