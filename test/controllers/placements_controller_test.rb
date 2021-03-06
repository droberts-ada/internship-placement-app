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

    expect(flash[:status]).must_equal :failure
    expect(flash[:message]).must_match(/no students/i)
  end

  test "Create a placement on a non-existant classroom fails" do
    invalid_classroom_id = Classroom.maximum(:id).next
    post classroom_placements_path(invalid_classroom_id)

    assert_response :redirect
    must_redirect_to classroom_path(invalid_classroom_id)

    expect(flash[:status]).must_equal :failure
    expect(flash[:message]).must_equal "Could not create placement"
  end

  test "Update a placement" do
    placement = Placement.create!(
      classroom_id: Classroom.find_by(name: "solver_test").id,
      owner: User.first)

    put placement_path(placement), params: {
          placement: {
            pairings: [
              placement.companies.first.id,
              placement.students.last.id
            ]
          }
        }

    assert_response :success
  end

  test "Update a placement with an invalid pairing" do
    put placement_path(Placement.first), params: {
          placement: {
            pairings: [Company.first.id, Student.first.id]
          }
        }

    assert_response :bad_request
  end

  test "Duplicates a placement" do
    placement = Placement.create!(
      classroom_id: Classroom.find_by(name: "solver_test").id,
      owner: User.first)

    # HTML
    post duplicate_placement_path(placement), format: :html

    assert_response :redirect
    must_redirect_to placement_path(Placement.last)

    # JSON
    post duplicate_placement_path(placement), format: :json

    assert_response :success
  end

  test "Duplicates a solved placement" do
    placement = Placement.create!(
      classroom_id: Classroom.find_by(name: "solver_test").id,
      owner: User.first)
    placement.solve

    # HTML
    post duplicate_placement_path(placement), format: :html

    assert_response :redirect
    must_redirect_to placement_path(Placement.last)

    # JSON
    post duplicate_placement_path(placement), format: :json

    assert_response :success
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
