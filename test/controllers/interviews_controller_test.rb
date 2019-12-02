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
    let(:morning_times) do
      [
        "09:00:00 -0800",
        "09:40:00 -0800",
        "10:20:00 -0800",
        "11:00:00 -0800",
        "11:40:00 -0800",
        "12:20:00 -0800"
      ]
    end

    let(:afternoon_times) do
      [
        "13:00:00 -0800",
        "13:40:00 -0800",
        "14:20:00 -0800",
        "15:00:00 -0800",
        "15:40:00 -0800",
        "16:20:00 -0800",
      ]
    end

    let(:student_names) do
      [
        "Gideon Jura",
        "Jace Beleren",
        "Liliana Vess",
        "Chandra Nalaar",
        "Nissa Revane",
        "Ajani Goldmane"
      ]
    end

    let(:morning_params) do
      {
        date: Date.today + 1,
        students: student_names.join("\n"),
        commit: "Morning"
      }
    end

    let(:afternoon_params) do
      {
        date: Date.today + 1,
        students: student_names.join("\n"),
        commit: "Afternoon"
      }
    end

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

    it "rejects an invalid date" do
      params = morning_params
      params[:date] = "never"

      expect do
        post company_interviews_path(Company.first.uuid), params: params
      end.wont_change -> { Interview.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message].downcase).must_include "date"
    end

    it "requires students" do
      params = morning_params
      params[:students] = nil

      expect do
        expect do
          post company_interviews_path(Company.first.uuid), params: params
        end.wont_change -> { Interview.count }
      end.wont_change -> { Student.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message].downcase).must_include "failed"
      expect(flash[:message].downcase).must_include "students"
    end

    it "requires all students" do
      params = morning_params
      names = student_names

      names.delete("Gideon Jura")
      params[:students] = names.join("\n")

      expect do
        expect do
          post company_interviews_path(Company.first.uuid), params: params
        end.wont_change -> { Interview.count }
      end.wont_change -> { Student.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message].downcase).must_include "failed"
      expect(flash[:message].downcase).must_include "students"
      expect(flash[:message].downcase).must_include "6"
      expect(flash[:message].downcase).must_include "5"
    end

    it "rejects invalid times" do
      params = morning_params
      params[:commit] = "evening"

      expect do
        expect do
          post company_interviews_path(Company.first.uuid), params: params
        end.wont_change -> { Interview.count }
      end.wont_change -> { Student.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_include "evening"
    end

    it "rejects too many interviews" do
      classroom = Classroom.create!(name: "Too Many Interviews!",creator: User.first, interviews_per_slot: 7)
      company = Company.create!(name: "Too Many Interviews!", classroom: classroom, slots: 1)

      expect do
        expect do
          post company_interviews_path(company.reload.uuid), params: morning_params
        end.wont_change -> { Interview.count }
      end.wont_change -> { Student.count }

      must_respond_with :bad_request
      expect(flash[:status]).must_equal :failure
    end

    it "can schedule morning interviews for new students" do
      company = Company.first
      student_names.each do |name|
        expect(Student.find_by(name: name)).must_be_nil
      end

      expect do
        expect do
          post(company_interviews_path(company.uuid), params: morning_params)
        end.must_change -> { Interview.count }, +6
      end.must_change -> { Student.count }, +6

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      expect(flash[:status]).must_equal :success

      student_names.each_with_index do |name, i|
        student = Student.find_by(name: name)
        expect(student.name).must_equal name

        interview = Interview.find_by(student: student)

        expect(interview).wont_be_nil
        expect(interview.scheduled_at.to_s).must_equal "#{morning_params[:date]} #{morning_times[i]}"
      end
    end

    it "can schedule afternoon interviews for new students" do
      company = Company.first
      student_names.each do |name|
        expect(Student.find_by(name: name)).must_be_nil
      end

      expect do
        expect do
          post(company_interviews_path(company.uuid), params: afternoon_params)
        end.must_change -> { Interview.count }, +6
      end.must_change -> { Student.count }, +6

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      expect(flash[:status]).must_equal :success

      student_names.each_with_index do |name, i|
        student = Student.find_by(name: name)
        expect(student.name).must_equal name

        interview = Interview.find_by(student: student)

        expect(interview).wont_be_nil

        expect(interview.scheduled_at.to_s).must_equal "#{afternoon_params[:date]} #{afternoon_times[i]}"
      end
    end

    it "can schedule morning interviews for existing students" do
      company = Company.first

      student_names.each do |name|
        Student.create!(name: name, classroom: company.classroom)
      end

      expect do
        expect do
          post(company_interviews_path(company.uuid), params: morning_params)
        end.must_change -> { Interview.count }, +6
      end.wont_change -> { Student.count }

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      expect(flash[:status]).must_equal :success

      student_names.each_with_index do |name, i|
        student = Student.find_by(name: name)
        expect(student.name).must_equal name

        interview = Interview.find_by(student: student)

        expect(interview).wont_be_nil
        expect(interview.scheduled_at.to_s).must_equal "#{morning_params[:date]} #{morning_times[i]}"
      end
    end

    it "can schedule afternoon interviews for existing students" do
      company = Company.first

      student_names.each do |name|
        Student.create!(name: name, classroom: company.classroom)
      end

      expect do
        expect do
          post(company_interviews_path(company.uuid), params: afternoon_params)
        end.must_change -> { Interview.count }, +6
      end.wont_change -> { Student.count }

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      expect(flash[:status]).must_equal :success

      student_names.each_with_index do |name, i|
        student = Student.find_by(name: name)
        expect(student.name).must_equal name

        interview = Interview.find_by(student: student)

        expect(interview).wont_be_nil
        expect(interview.scheduled_at.to_s).must_equal "#{afternoon_params[:date]} #{afternoon_times[i]}"
      end
    end

    it "can schedule afternoon interviews for existing students with whitespace" do
      company = Company.first

      student_names.each do |name|
        Student.create!(name: name, classroom: company.classroom)
      end

      params = afternoon_params
      params[:students] = student_names.join(" \n")

      expect do
        expect do
          post(company_interviews_path(company.uuid), params: params)
        end.must_change -> { Interview.count }, +6
      end.must_change -> { Student.count }, +6

      must_respond_with :redirect
      must_redirect_to company_path(company.uuid)

      expect(flash[:status]).must_equal :success

      student_names.each_with_index do |name|
        student = Student.find_by(name: name)
        expect(student.name).must_equal name

        interview = Interview.find_by(student: student)

        expect(interview).wont_be_nil
        expect(interview.scheduled_at.to_s).must_equal "#{afternoon_params[:date]} #{afternoon_times[i]}"
      end
    end
  end
end
