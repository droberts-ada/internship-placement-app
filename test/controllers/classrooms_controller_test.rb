require 'json'

require 'test_helper'

describe ClassroomsController do
  before do
    login_user users(:instructor)
  end

  describe 'index' do
    it 'returns FAILURE without logging in' do
      logout_user

      get classrooms_path

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it 'returns SUCCESS when logged in' do
      get classrooms_path

      must_respond_with :success
    end

    it 'refreshes token if expired and fails if upstream fails' do
      logout_user

      user = User.first

      stub_request(:post, ApplicationController::REFRESH_URL)
        .to_return(status: 200,
                   body: JSON.generate({
                                         access_token: SecureRandom.base64(128),
                                         expires_in: (Time.now + 8.hours).to_i
                                       }),
                   headers: {
                     "Content-Type": "application/json"
                   })

      expired_auth_hash = {
        provider: user.oauth_provider,
        uid: user.oauth_uid,
        info: {
          name: user.name,
          email: user.email
        },
        credentials: {
          token: SecureRandom.base64(128),
          refresh_token: SecureRandom.base64(64),
          expires_at: Time.now - 8.hours
        }
      }

      auth_hash = OmniAuth::AuthHash.new(expired_auth_hash)
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash

      get auth_callback_path(:google_oauth2)
      must_respond_with :redirect

      get classrooms_path
      must_respond_with :success
      expect(flash[:status]).must_equal nil
    end

    it 'refreshes token if expired and fails if upstream fails' do
      logout_user

      user = User.first

      stub_request(:post, ApplicationController::REFRESH_URL)
        .to_return(status: 401, body: "", headers: {})

      expired_auth_hash = {
        provider: user.oauth_provider,
        uid: user.oauth_uid,
        info: {
          name: user.name,
          email: user.email
        },
        credentials: {
          token: SecureRandom.base64(128),
          refresh_token: SecureRandom.base64(64),
          expires_at: Time.now - 8.hours
        }
      }

      auth_hash = OmniAuth::AuthHash.new(expired_auth_hash)
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash

      get auth_callback_path(:google_oauth2)
      must_respond_with :redirect

      get classrooms_path
      must_respond_with :unauthorized
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/refreshing/i)
      expect(flash[:message]).must_match(/failed/i)
    end
  end

  describe 'new' do
    it 'returns FAILURE without logging in' do
      logout_user

      get new_classroom_path

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it 'returns SUCCESS when logged in' do
      get new_classroom_path

      must_respond_with :success
    end
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

    let(:params_good) do
      {
        classroom: {
          name: 'Test classroom',
          interviews_per_slot: 2,
        },
        interviews_csv: interviews_good,
      }
    end

    let(:params_bad) { params_good.merge(classroom: {name: ''}) }

    let(:params_interviews_bad) do
      params_good.merge(interviews_csv: interviews_bad)
    end

    let(:params_interviews_malformed) do
      params_good.merge(interviews_csv: interviews_malformed)
    end

    it 'returns FAILURE without logging in' do
      logout_user

      post classrooms_path, params: params_good

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it 'redirects to the classroom details page' do
      post classrooms_path, params: params_good

      new_classroom = Classroom.last
      must_respond_with :redirect
      must_redirect_to classroom_path(new_classroom)

      expect(flash[:status]).must_equal :success
      expect(flash[:message]).must_match(/created classroom/i)
      expect(flash[:errors]).must_be_nil
    end

    it 'redirects to the classroom details page when generating' do
      post classrooms_path, params: { generate: "true" }

      new_classroom = Classroom.last
      must_respond_with :redirect
      must_redirect_to classroom_path(new_classroom)

      expect(flash[:status]).must_equal :success
      expect(flash[:message]).must_match(/created classroom/i)
      expect(flash[:errors]).must_be_nil
    end

    it 'returns 400 Bad Request with no name' do
      post classrooms_path, params: params_bad

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/could not/i)
      expect(flash[:message]).must_match(/create classroom/i)
      expect(flash[:errors]).must_be_kind_of Hash
      expect(flash[:errors].keys).must_include :name
    end

    it 'returns 400 Bad Request with bad interviews file' do
      post classrooms_path, params: params_interviews_bad

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/could not/i)
      expect(flash[:message]).must_match(/create classroom/i)
      expect(flash[:errors]).must_be_kind_of Hash
    end

    it 'returns 400 Bad Request with no interviews CSV file' do
      params_good[:interviews_csv] = nil

      post classrooms_path, params: params_good

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/could not/i)
      expect(flash[:message]).must_match(/csv file/i)
      expect(flash[:errors]).must_be_kind_of Hash
      expect(flash[:errors].keys).must_include :interviews_csv
    end

    it 'returns 400 Bad Request with malformed interviews CSV file' do
      post classrooms_path, params: params_interviews_malformed

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/could not/i)
      expect(flash[:message]).must_match(/csv file/i)
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

  describe 'show' do
    it "can successfully show a classroom" do
      get classroom_path(Classroom.first)

      must_respond_with :success
    end

    it "returns not_found for a missing classroom" do
      get classroom_path(Classroom.maximum(:id).next)

      must_respond_with :not_found
    end
  end

  describe 'edit' do
    it "can successfully edit a classroom" do
      get edit_classroom_path(Classroom.first)

      must_respond_with :success
    end

    it "returns not_found for a missing classroom" do
      get edit_classroom_path(Classroom.maximum(:id).next)

      must_respond_with :not_found
    end
  end


  describe 'update' do
    it 'returns FAILURE without logging in' do
      logout_user

      put classroom_path(Classroom.last.id)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it "returns not_found for a missing classroom" do
      put classroom_path(Classroom.maximum(:id).next)

      must_respond_with :not_found
    end

    it 'successfully updates name and interviews_per_slot' do
      updated_slots = 1
      updated_name = "Updated Name!"
      classroom = Classroom.last

      expect(classroom.name).wont_equal updated_name
      expect(classroom.interviews_per_slot).wont_equal updated_slots

      put(classroom_path(classroom),
          params: {
            classroom: {
              name: updated_name,
              interviews_per_slot: updated_slots
            }
          })

      must_respond_with :redirect
      must_redirect_to classroom_path(Classroom.last.id)

      expect(flash[:status]).must_equal :success
      expect(flash[:message]).must_match(/updated/i)

      classroom.reload

      expect(classroom.name).must_equal updated_name
      expect(classroom.interviews_per_slot).must_equal updated_slots
    end

    it 'fails to update to nil interviews_per_slot' do
      classroom = Classroom.last

      expect(classroom.interviews_per_slot).wont_be_nil

      put(classroom_path(classroom),
          params: {
            classroom: {
              interviews_per_slot: nil
            }
          })

      must_respond_with :bad_request

      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/could not/i)
      expect(flash[:message]).must_match(/update/i)
    end
  end

  describe 'destroy' do
    it "Successfully destroys a classroom" do
      classroom = Classroom.create!(creator: User.first, name: "Doomed Classroom")

      delete classroom_path(classroom)

      must_respond_with :redirect
      must_redirect_to classrooms_path

      expect(Classroom.find_by(id: classroom.id)).must_be_nil
    end

    it "returns not_found for a missing classroom" do
      delete classroom_path(Classroom.maximum(:id).next)

      must_respond_with :not_found
    end
  end

  describe 'export_feedback' do
    let(:classroom) { classrooms(:jets) }

    it 'returns FAILURE without logging in' do
      logout_user

      get export_feedback_classroom_path(classroom.id)

      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
      expect(flash[:message]).must_match(/log.*in/i)
    end

    it 'responds with a CSV file download' do
      get export_feedback_classroom_path(classroom.id)

      must_respond_with :success

      h = response.headers
      expect(h).must_include 'Content-Type'
      expect(h['Content-Type']).must_equal Mime[:csv]

      expect(h).must_include 'Content-Disposition'
      expect(h['Content-Disposition']).must_match(/^attachment;/)
      expect(h['Content-Disposition']).must_match(/filename=".+\.csv"/)

      expect(h).must_include 'Content-Transfer-Encoding'
      expect(h['Content-Transfer-Encoding']).must_equal 'binary'
    end

    it 'returns valid CSV data in the response body' do
      get export_feedback_classroom_path(classroom.id)

      rows = CSV.parse(response.body)
      expect(rows.length).must_be :>, 0
    end

    # TODO: Test the data returned more thoroughly
    # e.g. returns all data for this classroom, and only that data
  end
end
