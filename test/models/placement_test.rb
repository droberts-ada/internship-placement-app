require 'test_helper'

class PlacementTest < ActiveSupport::TestCase
  #
  # Constructor
  #
  test "Create a placement" do
    Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))
  end

  test "Cannot create a placement without a classroom" do
    p = Placement.new
    assert_not p.valid?
    assert_includes p.errors.messages, :classroom
  end

  test "Cannot create a placement without an owner" do
    p = Placement.new
    assert_not p.valid?
    assert_includes p.errors.messages, :owner
  end

  test "Placement gets students and companies through classroom" do
    p = Placement.new(classroom: classrooms(:jets))

    assert_equal p.students.length, classrooms(:jets).students.length
    assert_equal p.companies.length, classrooms(:jets).companies.length
  end

  #
  # set_pairings
  #
  test "Set valid pairings" do
    p = Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))

    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:space_labs).id
    } ]

    result = p.set_pairings(pairings)
    assert_equal result, p.pairings

    assert_equal p.pairings.length, pairings.length
    pair = p.pairings.first
    assert_equal pair.placement, p
    assert_equal pair.student_id, pairings.first[:student_id]
    assert_equal pair.company_id, pairings.first[:company_id]
  end

  test "Cannot set an invalid pairing" do
    p = Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))

    # Attempt to assign the student to multiple companies
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:space_labs).id
    }, {
      student_id: students(:ada).id,
      company_id: companies(:freedom_inc).id
    } ]

    exception = assert_raises ActiveRecord::RecordInvalid do
      p.set_pairings(pairings)
    end
    messages = exception.record.errors.messages
    assert_includes messages, :student
  end

  test "Calling set_pairings deletes old pairings" do
    p = Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))

    # First, create a valid pairing
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:stark).id
    } ];

    p.set_pairings(pairings)
    before_pairs = Placement.find(p.id).pairings
    assert_equal 1, before_pairs.length

    # Next, overwrite with a different, equally valid pairing
    pairings = [ {
      student_id: students(:grace).id,
      company_id: companies(:space_labs).id
    } ];

    p.set_pairings(pairings)
    after_pairs = Placement.find(p.id).pairings
    assert_equal 1, after_pairs.length

    assert_not_equal before_pairs.first.student_id, after_pairs.first.student_id
    assert_not_equal before_pairs.first.company_id, after_pairs.first.company_id
  end

  test "Previous and new pairing state do not conflict" do
    p = Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))

    # First, create a valid pairing
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:stark).id
    } ];

    p.set_pairings(pairings)
    before_pairs = Placement.find(p.id).pairings
    assert_equal 1, before_pairs.length

    # If we tried to add an ada-space pairing to the existing
    # ada-stark pairing, it would be bad. However, since set_pairings
    # replaces old pairings, we should be fine.
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:space_labs).id
    } ];

    # Expect no exception
    p.set_pairings(pairings)
  end

  test "Attempting to set invalid pairings rolls back to valid state" do
    p = Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))

    # First, create a valid pairing
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:stark).id
    } ];

    p.set_pairings(pairings)
    before_pages = Placement.find(p.id).pairings
    assert_equal before_pages, p.pairings

    # Next, attempt to overwrite with an invalid pairing
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:space_labs).id
    }, {
      student_id: students(:ada).id,
      company_id: companies(:freedom_inc).id
    } ]

    exception = assert_raises ActiveRecord::RecordInvalid do
      p.set_pairings(pairings)
    end
    messages = exception.record.errors.messages
    assert_includes messages, :student

    # Reload current pairings from the DB, verify they are unchanged
    after_pages = Placement.find(p.id).pairings
    assert_equal before_pages, after_pages
  end

  test "Calling set_pairings with no arguments will clear pairings" do
    p = Placement.create!(classroom: classrooms(:jets), owner: users(:instructor))

    # First, create a valid pairing
    pairings = [ {
      student_id: students(:ada).id,
      company_id: companies(:stark).id
    } ];

    p.set_pairings(pairings)
    before_pairs = Placement.find(p.id).pairings
    assert_equal 1, before_pairs.length

    # Now, remove pairings
    p.set_pairings
    after_pairs = Placement.find(p.id).pairings
    assert_equal 0, after_pairs.length
  end
end
