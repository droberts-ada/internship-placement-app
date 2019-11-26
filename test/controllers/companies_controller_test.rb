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

  describe "new" do
    it "returns FAILURE when not logged in" do
      get new_company_path

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns SUCCESS when logged in" do
      login_user(User.first)
      get new_company_path

      must_respond_with :success
    end
  end

  describe "create" do
    let :good_company_params do
      { company:
          {
            name: "Mystery Inc.",
            slots: 5,
            classroom_id: Classroom.first.id
          }
      }
    end

    it "returns FAILURE when not logged in" do
      post companies_path

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "can create a company with simple fields when logged in" do
      login_user(User.first)

      expect do
        post(companies_path, params: good_company_params)
      end.must_change -> { Company.count }, +1

      must_respond_with :redirect
      must_redirect_to company_path(Company.last.uuid)
    end

    it "can create a company with emails" do
      emails = ["dee@adadev.org", "devin@adadev.org"].join(",")

      login_user(User.first)

      params = good_company_params
      params[:company][:emails] = emails

      expect do
        post companies_path, params: params
      end.must_change -> { Company.count }, +1

      company = Company.last

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      expect(company.emails.length).must_equal 2
    end

    it "can't create a company with an invalid number of slots" do
      login_user(User.first)

      params = good_company_params
      params[:company][:slots] = 0

      expect do
        post companies_path, params: params
      end.wont_change -> { Company.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/create/i)
      expect(flash[:message]).must_match(/company/i)
    end
  end

  describe "edit" do
    it "returns FAILURE when not logged in" do
      get edit_company_path(Company.first.uuid)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns SUCCESS when logged in" do
      login_user(User.first)
      get edit_company_path(Company.first.uuid)

      must_respond_with :success
    end

    it "returns not_found for a missing company" do
      login_user(User.first)
      get edit_company_path("not-a-real-uuid")

      must_respond_with :not_found
    end
  end

  describe "update" do
    it "returns FAILURE when not logged in" do
      # PUT
      put company_path(Company.first.uuid)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)

      # PATCH
      patch company_path(Company.first.uuid)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns SUCCESS when logged in" do
      login_user(User.first)

      # PUT
      put(company_path(Company.first.uuid), params: { company: Company.first.attributes })

      must_respond_with :redirect
      must_redirect_to companies_path

      # PATCH
      patch(company_path(Company.first.uuid), params: { company: Company.first.attributes })

      must_respond_with :redirect
      must_redirect_to companies_path
    end

    it "returns not_found for a missing company" do
      login_user(User.first)

      # PUT
      put company_path("not-a-real-uuid")

      must_respond_with :not_found

      # PATCH
      patch company_path("not-a-real-uuid")

      must_respond_with :not_found
    end

    it "can update simple fields via put" do
      login_user(User.first)
      company = Company.first

      new_name = "A new name!"
      new_classroom = Classroom.create!(creator: User.first, name: new_name)
      new_slots = company.slots + 1

      params = { company: company.attributes }

      params[:company][:name] = new_name
      params[:company][:classroom_id] = new_classroom.id
      params[:company][:slots] = new_slots

      company.reload
      expect(company.name).wont_equal new_name

      put(company_path(company.uuid), params: params)

      must_respond_with :redirect
      must_redirect_to companies_path

      company.reload
      expect(company.name).must_equal new_name
    end

    it "can update simple fields via patch" do
      login_user(User.first)
      company = Company.first

      new_name = "A new name!"
      new_classroom = Classroom.create!(creator: User.first, name: new_name)
      new_slots = company.slots + 1

      params = { company: company.attributes }

      params[:company][:name] = new_name
      params[:company][:classroom_id] = new_classroom.id
      params[:company][:slots] = new_slots

      company.reload
      expect(company.name).wont_equal new_name

      patch(company_path(company.uuid), params: params)

      must_respond_with :redirect
      must_redirect_to companies_path

      company.reload
      expect(company.name).must_equal new_name
    end

    it "can update emails via put" do
      emails = ["dee@adadev.org", "devin@adadev.org"].join(",")

      login_user(User.first)
      company = Company.first
      expect(company.emails.length).must_equal 0

      params = { company: company.attributes }
      params[:company][:emails] = emails

      patch(company_path(company.uuid), params: params)

      must_respond_with :redirect
      must_redirect_to companies_path

      company.reload
      expect(company.emails.length).must_equal 2
    end

    it "can update emails via patch" do
      emails = ["dee@adadev.org", "devin@adadev.org"].join(",")

      login_user(User.first)
      company = Company.first
      expect(company.emails.length).must_equal 0

      params = { company: company.attributes }
      params[:company][:emails] = emails

      patch(company_path(company.uuid), params: params)

      must_respond_with :redirect
      must_redirect_to companies_path

      company.reload
      expect(company.emails.length).must_equal 2
    end

    it "can't update an invalid number of slots" do
      login_user(User.first)
      company = Company.first

      params = { company: company.attributes }

      params[:company][:slots] = 0

      patch(company_path(company.uuid), params: params)

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/update/i)
      expect(flash[:message]).must_match(/company/i)

      company.reload
      expect(company.slots).wont_equal 0
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
        meet_with_lead: [4, 3, 2, 1, 2],
        meet_with_manager: [4, 3, 2, 1],
        manager_experience: [1, 0, 0],
        mentorship_experience: [1, 0, 0],
        team_age: [4, 3, 2, 1, 0],
        team_size: [4, 3, 2, 1]
      }
    end

    let(:survey_params) do
      {
        company_survey: {
          team_name: "good",
          pre_hiring_requirements: "none",
          onboarding: rand(4),
          pair_programming: rand(6),
          structure: rand(5),
          diverse_bg: rand(3),
          other_adies: rand(2),
          meet_with_mentor: rand(4),
          meet_with_lead: rand(4),
          meet_with_manager: rand(4),
          manager_experience: rand(3),
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
        expect(flash[:message].downcase).must_include "structure"
      end

      it "saves team_name, pre_hiring_requirements, preferred_students" do
        params = survey_params
        params[:company_survey][:team_name] = "Team Avatar"
        params[:company_survey][:pre_hiring_requirements] = "Must be okay with riding a flying bison."
        params[:company_survey][:preferred_students] = "Sokka,
Katara,
Toph"

        expect do
          post survey_company_path(Company.first.uuid), params: params
        end.must_change -> { CompanySurvey.count }, +1

        survey = CompanySurvey.last

        must_respond_with :redirect
        must_redirect_to company_path(survey.company.uuid)

        expect(survey.team_name).must_equal params[:company_survey][:team_name]
        expect(survey.pre_hiring_requirements).must_equal params[:company_survey][:pre_hiring_requirements]
        expect(survey.preferred_students).must_equal params[:company_survey][:preferred_students]
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

    describe "update" do
      describe "put" do
        it "returns FAILURE when not logged in" do
          put survey_company_path(Company.last.uuid)

          must_respond_with :redirect
          expect(flash[:status]).must_equal :failure
          expect(flash[:message]).must_match(/log.*in/i)
        end

        it "returns NOT FOUND if Company is missing" do
          login_user(User.first)

          put survey_company_path("invalid-uuid")

          must_respond_with :not_found
        end

        it "returns NOT FOUND if CompanySurvey is missing" do
          login_user(User.first)

          no_survey = Company.create!(classroom: Classroom.first, name: "no survey company", slots: 1)

          put survey_company_path(no_survey.reload.uuid)

          must_respond_with :not_found
        end

        it "can update team_name" do
          login_user(User.first)

          new_name = "Better!"

          company = Company.first
          survey = CompanySurvey.create!(survey_params[:company_survey].merge(company: company))

          params = survey_params
          params[:company_survey][:team_name] = new_name

          put survey_company_path(company.uuid), params: params

          flash[:status] = :success

          must_respond_with :redirect
          must_redirect_to company_path(company.uuid)

          expect(survey.reload.team_name).must_equal new_name
        end

        it "can't update a survey to remove :manager_experience" do
          login_user(User.first)

          CompanySurvey.create!(survey_params[:company_survey].merge(company: Company.first))

          params = survey_params
          params[:company_survey][:manager_experience] = nil

          put survey_company_path(Company.first.uuid), params: params

          must_respond_with :bad_request
          expect(flash[:status]).must_equal :failure
          expect(flash[:message].downcase).must_include "survey"
          expect(flash[:message].downcase).must_include "failed"
          expect(flash[:errors][:company_survey].length).must_equal 1
          expect(flash[:errors][:company_survey].first.downcase).must_include "manager experience"
        end
      end

      describe "patch" do
        it "returns FAILURE when not logged in" do
          patch survey_company_path(Company.last.uuid)

          must_respond_with :redirect
          expect(flash[:status]).must_equal :failure
          expect(flash[:message]).must_match(/log.*in/i)
        end

        it "returns NOT FOUND if Company is missing" do
          login_user(User.first)

          patch survey_company_path("invalid-uuid")

          must_respond_with :not_found
        end

        it "returns NOT FOUND if CompanySurvey is missing" do
          login_user(User.first)

          no_survey = Company.create!(classroom: Classroom.first, name: "no survey company", slots: 1)

          patch survey_company_path(no_survey.reload.uuid)

          must_respond_with :not_found
        end

        it "can update team_name" do
          login_user(User.first)

          new_name = "Better!"

          company = Company.first
          survey = CompanySurvey.create!(survey_params[:company_survey].merge(company: company))

          params = survey_params
          params[:company_survey][:team_name] = new_name

          patch survey_company_path(company.uuid), params: params

          flash[:status] = :success

          must_respond_with :redirect
          must_redirect_to company_path(company.uuid)

          expect(survey.reload.team_name).must_equal new_name
        end

        it "can't update a survey to remove :manager_experience" do
          login_user(User.first)

          CompanySurvey.create!(survey_params[:company_survey].merge(company: Company.first))

          params = survey_params
          params[:company_survey][:manager_experience] = nil

          patch survey_company_path(Company.first.uuid), params: params

          must_respond_with :bad_request
          expect(flash[:status]).must_equal :failure
          expect(flash[:message].downcase).must_include "survey"
          expect(flash[:message].downcase).must_include "failed"
          expect(flash[:errors][:company_survey].length).must_equal 1
          expect(flash[:errors][:company_survey].first.downcase).must_include "manager experience"
        end
      end
    end
  end
end
