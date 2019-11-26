require "test_helper"

describe InterviewsController do
  before do
    login_user(User.first)
  end

  describe "new" do
    it "returns FAILURE when not logged in" do
      logout_user

      get new_company_interview_path(Company.first.uuid)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns SUCCESS when logged in" do
      login_user(User.first)
      get new_company_interview_path(Company.first.uuid)

      must_respond_with :success
    end

    it "returns NOT_FOUND when company is missing" do
      login_user(User.first)
      get new_company_interview_path("invalid-uuid")

      must_respond_with :not_found
    end
  end

  describe "create" do
    it "returns FAILURE when not logged in" do
      logout_user

      post company_interviews_path(Company.first.uuid)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns NOT_FOUND when company is missing" do
      post company_interviews_path("invalid-uuid")

      must_respond_with :not_found
    end

    it "requires student_name" do
      params = {
        interview: {
          scheduled_at: Time.now + 1.day
        },
      }

      expect do
        expect do
          post company_interviews_path(Company.first.uuid), params: params
        end.wont_change -> { Interview.count }
      end.wont_change -> { Student.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_include "student_name"
    end

    it "can schedule an interview for a new student" do
      name = "Nissa Revane"
      time = Time.now + 1.day

      params = {
        interview: {
          scheduled_at: time
        },
        student_name: name
      }

      company = Company.first
      expect(Student.find_by(name: name)).must_be_nil

      expect do
        expect do
          post(company_interviews_path(company.uuid), params: params)
        end.must_change -> { Interview.count }, +1
      end.must_change -> { Student.count }, +1

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      student = Student.find_by(name: name)
      expect(student.name).must_equal name

      interview = Interview.last

      expect(interview.student).must_equal student
      expect(interview.scheduled_at.to_s).must_equal time.to_s

      expect(flash[:status]).must_equal :success
    end

    it "can schedule an interview for an existing student" do
      name = "Chandra Nalaar"
      time = Time.now + 2.days

      params = {
        interview: {
          scheduled_at: time
        },
        student_name: name
      }

      company = Company.first
      student = Student.create!(name: name, classroom: company.classroom)

      expect do
        expect do
          post company_interviews_path(company.uuid), params: params
        end.must_change -> { Interview.count }, +1
      end.wont_change -> { Student.count }

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      interview = Interview.last
      expect(interview.student).must_equal student
      expect(interview.scheduled_at.to_s).must_equal time.to_s

      expect(flash[:status]).must_equal :success
    end

    it "rejects an invalid time" do
      params = {
        interview: {
          scheduled_at: "tomorrow"
        },
        student_name: "Teferi"
      }

      expect do
        post company_interviews_path(Company.first.uuid), params: params
      end.wont_change -> { Interview.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_include "Scheduled at"
    end
  end
end
