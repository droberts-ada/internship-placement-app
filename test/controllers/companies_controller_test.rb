require "test_helper"

describe CompaniesController do
  describe "index" do
    it "returns FAILURE when not logged in" do
      get companies_path

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns SUCCESS when logged in" do
      login_user(User.first)
      get companies_path

      must_respond_with :success
    end
  end

  describe "show" do
    it "returns SUCCESS without logging in" do
      Interview.create!(student: Student.first,
                        company: Company.first,
                        scheduled_at: Date.today + 1)

      get company_path(Company.first.uuid)

      must_respond_with :success
    end

    it "returns NOT FOUND if Company is missing" do
      get company_path("invalid-uuid")

      must_respond_with :not_found
    end
  end

  describe "survey" do
    let(:survey_params) do
      {
        company_survey: {
          onboarding: rand(4),
          pair_programming: rand(6),
          structure: rand(5),
          diverse_bg: rand(3),
          other_adies: rand(2),
          meet_with_mentor: rand(4),
          meet_with_lead: rand(4),
          meet_with_manager: rand(4),
          mentorship_experience: rand(3),
          team_age: rand(5),
          team_size: rand(4),
        }
      }
    end

    let(:survey_params_missing_structure) do
      {
        company_survey: {
          onboarding: rand(4),
          pair_programming: rand(6),
          diverse_bg: rand(3),
          other_adies: rand(2),
          meet_with_mentor: rand(4),
          meet_with_lead: rand(4),
          meet_with_manager: rand(4),
          mentorship_experience: rand(3),
          team_age: rand(5),
          team_size: rand(4),
        }
      }
    end

    describe "create" do
      it "returns NOT FOUND if Company is missing" do
        post survey_company_path("invalid-uuid")

        must_respond_with :not_found
      end

      it "can't create a survey without :structure" do
        expect do
          post survey_company_path(Company.first.uuid), params: survey_params_missing_structure
        end.wont_change -> { CompanySurvey.count }

        must_respond_with :bad_request
        expect(flash[:status]).must_equal :failure
        expect(flash[:message].downcase).must_include "survey"
        expect(flash[:message].downcase).must_include "failed"
        expect(flash[:errors][:company_survey].length).must_equal 1
        expect(flash[:errors][:company_survey].first.downcase).must_include "structure"
      end

      it "must create a survey" do
        expect do
          post survey_company_path(Company.first.uuid), params: survey_params
        end.must_change -> { CompanySurvey.count }, +1

        must_respond_with :redirect
        must_redirect_to company_path(Company.first.uuid)

        expect(flash[:status]).must_equal :success
        expect(flash[:message].downcase).must_include "submit"
      end
    end
  end
end
