require 'test_helper'

describe PlacementsController do
  before do
    login_user(users(:instructor))
  end

  test "Get list of placements" do
    get placements_path
    assert_response :success
  end

  test "Create a placement" do
    classroom = Classroom.create!(name: 'Test', creator: User.first)
    post classroom_placements_path(classroom)

    assert_response :redirect
    must_redirect_to placement_path(Placement.last)
  end

  test "Create a placement and run the solver" do
    post classroom_placements_path(Classroom.find_by(name: "solver_test")), params: {run_solver: true}

    assert_response :redirect
    must_redirect_to placement_path(Placement.last)
  end

  test "Create a placement and run the solver on a bad classroom" do
    classroom = Classroom.create!(name: 'Test', creator: User.first)
    post classroom_placements_path(classroom), params: {run_solver: true}

    assert_response :redirect
    must_redirect_to classroom_path(classroom)
  end

  test "Show a real placement" do
    get placement_path(placements(:full))
    assert_response :success
  end

  test "Show a placement that D.N.E." do
    invalid_placement_id = Placement.maximum(:id).next

    assert_nil Placement.find_by(id: invalid_placement_id)

    get placement_path(invalid_placement_id)
    assert_response :not_found
  end
end
