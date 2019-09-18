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
    let(:question_points) do
      {
        onboarding: [4, 3, 0, 0],
        pair_programming: [5, 4, 3, 2, 1, 0],
        structure: [5, 3, 2, 0, 1],
        diverse_bg: [2, 1, 0],
        other_adies: [1, 0],
        meet_with_mentor: [4, 3, 2, 1],
        meet_with_lead: [4, 3, 2, 1],
        meet_with_manager: [4, 3, 2, 1],
        mentorship_experience: [1, 0, 0],
        team_age: [4, 3, 2, 1, 0],
        team_size: [4, 3, 2, 1]
      }
    end

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

      it "must create a survey with correct points" do
        expect do
          post survey_company_path(Company.first.uuid), params: survey_params
        end.must_change -> { CompanySurvey.count }, +1

        must_respond_with :redirect
        must_redirect_to company_path(Company.first.uuid)

        expect(flash[:status]).must_equal :success
        expect(flash[:message].downcase).must_include "submit"

        survey = CompanySurvey.last

        expect(survey.onboarding).must_equal(
          question_points[:onboarding][survey_params[:company_survey][:onboarding]]
        )
        expect(survey.pair_programming).must_equal(
          question_points[:pair_programming][survey_params[:company_survey][:pair_programming]]
        )
        expect(survey.diverse_bg).must_equal(
          question_points[:diverse_bg][survey_params[:company_survey][:diverse_bg]]
        )
        expect(survey.other_adies).must_equal(
          question_points[:other_adies][survey_params[:company_survey][:other_adies]]
        )
        expect(survey.meet_with_mentor).must_equal(
          question_points[:meet_with_mentor][survey_params[:company_survey][:meet_with_mentor]]
        )
        expect(survey.meet_with_lead).must_equal(
          question_points[:meet_with_lead][survey_params[:company_survey][:meet_with_lead]]
        )
        expect(survey.meet_with_manager).must_equal(
          question_points[:meet_with_manager][survey_params[:company_survey][:meet_with_manager]]
        )
        expect(survey.mentorship_experience).must_equal(
          question_points[:mentorship_experience][survey_params[:company_survey][:mentorship_experience]]
        )
        expect(survey.team_age).must_equal(
          question_points[:team_age][survey_params[:company_survey][:team_age]]
        )
        expect(survey.team_size).must_equal(
          question_points[:team_size][survey_params[:company_survey][:team_size]]
        )
      end
    end
  end
end
