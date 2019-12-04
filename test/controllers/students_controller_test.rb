require 'test_helper'

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
      interview = Interview.create!(
        student: @student,
        company: company,
        scheduled_at: Date.today + 1
      )

      InterviewFeedback.create!(
        interviewer_name: 'Lance',
        interview: interview,
        interview_result: 2,
        result_explanation: 'Pretty evil, but might make an okay gym leader.'
      )
    end
  end

  describe 'feedback' do
    it 'returns SUCCESS without logging in' do
      get feedback_students_path

      must_respond_with :success
    end
  end

  describe 'companies' do
    it 'returns all companies for students' do
      get companies_student_path(@student)

      must_respond_with :success
      parsed_names = JSON.parse(@response.body).map { |c| c['name'] }.sort

      expect(@company_names.sort).must_equal parsed_names
    end

    it 'renders not_found if student is missing' do
      get companies_student_path(Student.maximum(:id).next)

      must_respond_with :not_found
    end
  end

  describe 'rankings' do
    it 'properly stores company rankings' do
      params = @companies.each_with_index.map do |company, i|
        {
          company_id: company.id,
          rank: i + 1
        }
      end

      post(rankings_student_path(@student.id), params: { rankings: params })

      must_respond_with :success

      rankings = Interview.where(student: @student).map(&:ranking)

      expect(rankings.length).must_equal 6
      ranked_names = rankings.map { |r| r.interview.company.name }.sort
      ranks = rankings.map { |r| r.student_preference }.sort

      expect(ranked_names).must_equal @company_names.sort
      expect(ranks).must_equal [1, 4, 4, 5, 5, 5]
    end

    it 'rejects rankings without interview' do
      invalid_company = Company.create!(
        name: "Professor Oak's Lab",
        classroom: @student.classroom,
        slots: 6
      )

      companies = [invalid_company] + @companies.take(5)

      params = companies.each_with_index.map do |company, i|
        {
          company_id: company.id,
          rank: i + 1
        }
      end

      post(rankings_student_path(@student.id), params: { rankings: params })

      must_respond_with :bad_request
    end

    it 'Rejects invalid company rankings' do
      params = @companies.each_with_index.map do |company, i|
        {
          company_id: company.id,
          rank: 6
        }
      end

      post(rankings_student_path(@student.id), params: { rankings: params })

      must_respond_with :bad_request

      error = JSON.parse(@response.body)['error']
      expect(error.end_with?([6, 6, 6, 6, 6, 6].to_s)).must_equal true
    end

    it 'renders not_found if student is missing' do
      post rankings_student_path(Student.maximum(:id).next)

      must_respond_with :not_found
    end
  end
end
