require 'test_helper'

class PlacementTest < ActiveSupport::TestCase
  #
  # Constructor
  #
  test "Create a placement" do
    Placement.create!(classroom: classrooms(:jets))
  end

  test "Cannot create a placement without a classroom" do
    p = Placement.new
    assert_not p.valid?
    assert_includes p.errors.messages, :classroom
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
    p = Placement.create!(classroom: classrooms(:jets))

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
    p = Placement.create!(classroom: classrooms(:jets))

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
    p = Placement.create!(classroom: classrooms(:jets))

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
    p = Placement.create!(classroom: classrooms(:jets))

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
    p = Placement.create!(classroom: classrooms(:jets))

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
    p = Placement.create!(classroom: classrooms(:jets))

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

  let(:full_placement) do
    # HACK: Remove student "Mary Johnson" b/c they did not interview anywhere
    students(:no_company).destroy

    placements(:full)
  end

  test "Calling full? with all students placed will return true" do
    assert full_placement.full?
  end

  test "Calling full? with not all students placed will return false" do
    # Remove one of the pairings
    full_placement.pairings.first.destroy

    refute full_placement.full?
  end

  test "Calling as_rows with all students placed will return array of arrays" do
    assert_kind_of Array, full_placement.as_rows

    full_placement.as_rows.each do |row|
      assert_kind_of Array, row
    end
  end

  test "Calling as_rows with all students placed will return rows of pairings" do
    pairings = full_placement.pairings.map do |pair|
      [pair.student.name, pair.company.name]
    end

    assert_equal full_placement.as_rows.sort, pairings.sort
  end

  test "Calling as_rows with not all students placed raises RuntimeError" do
    # Remove one of the pairings
    full_placement.pairings.first.destroy

    assert_raise RuntimeError do
      full_placement.as_rows
    end
  end
end
