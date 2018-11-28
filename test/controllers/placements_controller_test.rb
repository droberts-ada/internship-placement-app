require 'test_helper'

describe PlacementsController do
  before do
    login_user(users(:instructor))
  end

  test "Get list of placements" do
    get placements_path
    assert_response :success
  end

  test "Show a real placement" do
    get placement_path(placements(:full))
    assert_response :success
  end

  test "Show a placement that D.N.E." do
    bogus_placement_id = 1337
    assert_nil Placement.find_by(id: bogus_placement_id)
    get placement_path(bogus_placement_id)
    assert_response :not_found
  end
end
