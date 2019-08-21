require 'test_helper'

describe CompaniesController do
  describe 'index' do
    it 'returns FAILURE without logging in' do
      get companies_path

      must_respond_with :redirect
    end
  end

  describe 'show' do
    it 'returns SUCCESS without logging in' do
      Interview.create!(student: Student.first,
                        company: Company.first,
                        scheduled_at: Date.today + 1)

      get company_path(Company.first.uuid)

      must_respond_with :success
    end

    it 'returns NOT FOUND if Company is missing' do
      get company_path('invalid-uuid')

      must_respond_with :not_found
    end
  end
end
