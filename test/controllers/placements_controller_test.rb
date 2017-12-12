require 'test_helper'

class PlacementsControllerTest < ActionController::TestCase
  test "Get list of placements" do
    get :index
    assert_response :success
    data = JSON.parse(@response.body)

    assert_equal Placement.count, data.length
  end

  test "Show a real placement" do
    get :show, params: {id: placements(:full).id}
    assert_response :success
    data = JSON.parse(@response.body)

    assert_includes data, 'id'
    assert_equal data['id'], placements(:full).id

    assert_includes data, 'students'
    assert_includes data, 'companies'
    assert_includes data, 'pairings'
  end

  test "Placement contains students" do
    get :show, params: {id: placements(:full).id}
    assert_response :success
    data = JSON.parse(@response.body)

    assert_includes data, 'students'
    assert_equal data['students'].length, placements(:full).students.count

    data['students'].each do |student|
      assert_includes student, 'id'
      assert_includes student, 'name'

      assert_includes student, 'rankings'
      assert_equal Student.find(student['id']).rankings.count, student['rankings'].length

      student['rankings'].each do |ranking|
        assert_includes ranking, 'student_preference'
        assert_kind_of Numeric, ranking['student_preference']

        assert_includes ranking, 'interview_result'
        assert_kind_of Numeric, ranking['interview_result']

        assert_includes ranking, 'company_id'
        assert_kind_of Numeric, ranking['company_id']
      end
    end
  end

  test "Placement contains companies" do
    get :show, params: {id: placements(:full).id}
    assert_response :success
    data = JSON.parse(@response.body)

    assert_includes data, 'companies'
    assert_equal data['companies'].length, placements(:full).companies.count

    data['companies'].each do |company|
      assert_includes company, 'id'
      assert_includes company, 'name'
    end
  end

  test "Placement contains pairings" do
    get :show, params: {id: placements(:full).id}
    assert_response :success
    data = JSON.parse(@response.body)

    assert_includes data, 'pairings'
    assert_equal data['pairings'].length, placements(:full).pairings.count

    data['pairings'].each do |pairing|
      assert_includes pairing, 'student_id'
      assert_not_nil placements(:full).students.find_by(id: pairing['student_id'])

      assert_includes pairing, 'company_id'
      assert_not_nil placements(:full).companies.find_by(id: pairing['company_id'])
    end
  end

  test "Show a placement that D.N.E." do
    bogus_placement_id = 1337
    assert_nil Placement.find_by(id: bogus_placement_id)
    get :show, params: {id: bogus_placement_id}
    assert_response :not_found
  end

  let(:full_placement) do
    # HACK: Remove student "Mary Johnson" b/c they did not interview anywhere
    students(:no_company).destroy

    placements(:full)
  end

  test "Exporting full placement returns Google Sheets URL" do
    # HACK: We're skipping the actual login flow that should be done
    session[:user_id] = users(:google_user).id

    VCR.use_cassette('placement_controller_export') do
      post :export, params: {id: full_placement.id, format: :json}
      assert_response :success
      data = JSON.parse(@response.body)

      assert_includes data, 'name'
      assert_includes data, 'url'

      assert_match /^https:\/\/docs\.google\.com\//, data['url']
    end
  end

  test "Exporting non-full placement returns error message" do
    # HACK: We're skipping the actual login flow that should be done
    session[:user_id] = users(:google_user).id

    # Remove one of the pairings
    full_placement.pairings.first.destroy

    VCR.use_cassette('placement_controller_export') do
      post :export, params: {id: full_placement.id, format: :json}
      assert_response :bad_request
      data = JSON.parse(@response.body)

      assert_includes data, 'errors'
      assert_kind_of Array, data['errors']
      refute_empty data['errors']
    end
  end
end
