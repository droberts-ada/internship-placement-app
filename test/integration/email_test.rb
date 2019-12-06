require "test_helper"

describe ApplicationController do
  # before do
  #   login_user(User.first)
  # end

  describe CompaniesController do
    describe "send_survey" do
      # These are integration tests because they require a functioning Amazon SDK to work.
      it "sends the survey to a good email when \"Create and Send Survey\" is selected" do
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

    describe "send_reminder" do
      it "can send" do
        VCR.use_cassette('amason-ses') do
          login_user(User.first)
          email = "success@simulator.amazonses.com"

          company = Company.create!(name: "Gatewatch Inc",
                                    classroom: Classroom.first,
                                    slots: 1,
                                    emails: [email]).reload

          post send_reminder_company_path(company.uuid)

          must_respond_with :redirect
          must_redirect_to companies_path

          expect(flash[:status]).must_equal :success
          expect(flash[:message].downcase).must_include("email")
          expect(flash[:message]).must_include(email)
        end
      end
    end
  end

  describe StudentsController do
    before do
      @student = Student.create!(
        name: "Giovanni",
        classroom: Classroom.first
      )

      @company_names = ['Silph Co.', 'Devon Corporation', 'City Rail',
                        'Pokemon Center', 'Pokemart', 'Pokemon League']

      @companies = @company_names.map do |name|
        Company.create!(
          name: name,
          classroom: @student.classroom,
          slots: 6
        )
      end

      @companies.each do |company|
        Interview.create!(
          student: @student,
          company: company,
          scheduled_at: Date.today + 1
        )
      end
    end

    it "sends the confirmation to a good email when email is provided" do
      VCR.use_cassette('amason-ses') do
        login_user(User.first)
        email = "success@simulator.amazonses.com"

        params = {
          email: email,
          rankings: @companies.each_with_index.map do |company, i|
            {
              company_id: company.id,
              rank: i + 1
            }
          end
        }

        post(rankings_student_path(@student.id), params: params)

        must_respond_with :success

        expect(flash[:status]).must_equal :success
        expect(flash[:message].downcase).must_include("email")
        expect(flash[:message]).must_include(email)
      end
    end
  end
end
