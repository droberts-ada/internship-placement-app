require 'test_helper'

describe ClassroomsController do
  before do
    login_user users(:instructor)
  end

  describe 'create' do
    let(:interviews_good) do
      fixture_file_upload('files/interviews_good.csv', 'text/csv')
    end

    let(:interviews_bad) do
      fixture_file_upload('files/interviews_bad.csv', 'text/csv')
    end

    let(:interviews_malformed) do
      fixture_file_upload('files/interviews_malformed.csv', 'text/csv')
    end

    let(:params_good) do {
      classroom: {
        name: 'Test classroom',
        interviews_per_slot: 2,
      },
      interviews_csv: interviews_good,
    } end

    let(:params_bad) { params_good.merge(classroom: {name: ''}) }

    let(:params_interviews_bad) do
      params_good.merge(interviews_csv: interviews_bad)
    end

    let(:params_interviews_malformed) do
      params_good.merge(interviews_csv: interviews_malformed)
    end

    it 'redirects to the classroom details page' do
      post classrooms_path, params: params_good

      new_classroom = Classroom.last
      must_respond_with :redirect
      must_redirect_to classroom_path(new_classroom)

      expect(flash[:status]).must_equal :success
      expect(flash[:message]).must_match /created classroom/
      expect(flash[:errors]).must_be_nil
    end

    it 'returns 400 Bad Request with no name' do
      post classrooms_path, params: params_bad

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_equal "could not create classroom"
      expect(flash[:errors]).must_be_kind_of Hash
      expect(flash[:errors].keys).must_include :name
    end

    it 'returns 400 Bad Request with bad interviews file' do
      post classrooms_path, params: params_interviews_bad

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_equal "could not create classroom"
      expect(flash[:errors]).must_be_kind_of Hash
    end

    it 'returns 400 Bad Request with no interviews CSV file' do
      params_good[:interviews_csv] = nil

      post classrooms_path, params: params_good

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_equal "could not use interviews CSV file"
      expect(flash[:errors]).must_be_kind_of Hash
      expect(flash[:errors].keys).must_include :interviews_csv
    end

    it 'returns 400 Bad Request with malformed interviews CSV file' do
      post classrooms_path, params: params_interviews_malformed

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_equal "could not use interviews CSV file"
      expect(flash[:errors]).must_be_kind_of Hash
      expect(flash[:errors].keys).must_include :interviews_csv
    end

    it 'creates a new Classroom model' do
      expect {
        post classrooms_path, params: params_good
      }.must_change -> { Classroom.count }, 1
    end

    it 'creates each interview from the CSV file' do
      # Note: hard-coded to the test data file
      expect {
        post classrooms_path, params: params_good
      }.must_change -> { Interview.count }, 8
    end

    it 'creates all students with interviews' do
      # Note: hard-coded to the test data file
      expect {
        post classrooms_path, params: params_good
      }.must_change -> { Student.count }, 4
    end

    it 'creates all companies doing interviews' do
      # Note: hard-coded to the test data file
      expect {
        post classrooms_path, params: params_good
      }.must_change -> { Company.count }, 2
    end

    it 'does not create any models when data is invalid' do
      cases = [params_bad, params_interviews_bad, params_interviews_malformed]
      cases.each do |params|
        expect do
          post classrooms_path, params: params
        end.wont_change -> do
          [Classroom, Interview, Student, Company].map(&:count).sum
        end
      end
    end
  end
end
