require 'test_helper'

describe Spreadsheet do
  describe '.export_data' do
    let(:user) { users(:google_user) }

    it 'should return a valid Google Sheets URL' do
      headers = ['Item', 'Price']
      rows = [['Pear', '2.50'],
              ['Watermelon', '5.16'],
              ['Apple', '1.07']]

      VCR.use_cassette('spreadsheet_export_data') do
        url = Spreadsheet.export_data(headers, rows, user)

        url.must_match /^https:\/\/docs\.google\.com\//
      end
    end
  end
end
