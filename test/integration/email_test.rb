require "test_helper"

describe CompaniesController do
  # These are integration tests because they require a functioning Amazon SDK to work.
  it "sends the survey to a good email when \"Save and Send Survey\" is selected" do
    VCR.use_cassette('amason-ses') do
      login_user(User.first)
      email = "success@simulator.amazonses.com"

      params = {
        company:
          {
            name: "Mystery Inc.",
            slots: 5,
            classroom_id: Classroom.first.id,
            emails: [email]
          },
        commit: "Save and Send Survey"
      }

      expect do
        post companies_path, params: params
      end.must_change -> { Company.count }, +1

      must_respond_with :redirect
      must_redirect_to company_path(Company.last.uuid)

      expect(flash[:status]).must_equal :success
      expect(flash[:message].downcase).must_include("email")
      expect(flash[:message]).must_include(email)
    end
  end

  it "Reports an error when the email fails to send" do
    stub_request(:post, "https://email.us-west-2.amazonaws.com/").to_return(status: 500)

    login_user(User.first)
    email = "bounce@simulator.amazonses.com"

    params = {
      company:
        {
          name: "Mystery Inc.",
          slots: 5,
          classroom_id: Classroom.first.id,
          emails: [email]
        },
      commit: "Save and Send Survey"
    }

    expect do
      post companies_path, params: params
    end.must_change -> { Company.count }, +1

    must_respond_with :redirect
    must_redirect_to company_path(Company.last.uuid)

    expect(flash[:status]).must_equal :failure
    expect(flash[:message].downcase).must_include("failed")
    expect(flash[:message].downcase).must_include("email")
  end
end
