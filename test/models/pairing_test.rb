require 'test_helper'

class PairingTest < ActiveSupport::TestCase
  test "Constructor success" do
    pairing_data = {
      placement: placements(:empty),
      student: students(:ada),
      company: companies(:space_labs)
    }
    Pairing.create!(pairing_data)
  end

  test "Cannot build pairing without placement" do
    pairing_data = {
      student: students(:no_company),
      company: companies(:no_students)
    }
    p = Pairing.create(pairing_data)
    assert_not p.valid?
    assert_includes p.errors.messages, :placement
  end

  test "Cannot build pairing without student" do
    pairing_data = {
      placement: placements(:empty),
      company: companies(:no_students)
    }
    p = Pairing.create(pairing_data)
    assert_not p.valid?
    assert_includes p.errors.messages, :student
  end

  test "Cannot build pairing without company" do
    pairing_data = {
      placement: placements(:empty),
      student: students(:no_company)
    }
    p = Pairing.create(pairing_data)
    assert_not p.valid?
    assert_includes p.errors.messages, :company
  end

  test "Cannot double-place a student in a pairing" do
    pairing_data = {
      placement: placements(:full),
      student: students(:anita),
      company: companies(:no_students)
    }
    p = Pairing.create(pairing_data)
    assert_not p.valid?
    assert_includes p.errors.messages, :student
  end

  test "Can create pairing for student that only appears in other placements" do
    assert_equal 1, Pairing.where(student: students(:anita),
                                  placement: placements(:full)).length
    assert_empty Pairing.where(student: students(:anita),
                               placement: placements(:empty))
    pairing_data = {
      placement: placements(:empty),
      student: students(:anita),
      company: companies(:space_labs)
    }
    Pairing.create!(pairing_data)
  end

  test "Cannot place a company in a pairing more times than it has slots" do
    assert_equal 1, companies(:freedom_inc).slots
    pairing_data = {
      placement: placements(:full),
      student: students(:no_company),
      company: companies(:freedom_inc)
    }
    p = Pairing.create(pairing_data)
    assert_not p.valid?
    assert_includes p.errors.messages, :company
  end

  test "Can create pairing for company that is full in a different placement" do
    assert_equal companies(:freedom_inc).slots,
                    Pairing.where(placement: placements(:full),
                                  company: companies(:freedom_inc)).length
    assert_empty Pairing.where(placement: placements(:empty),
                               company: companies(:freedom_inc))
    pairing_data = {
      placement: placements(:empty),
      student: students(:grace),
      company: companies(:freedom_inc)
    }
    assert_difference 'Pairing.count', 1 do
      Pairing.create!(pairing_data)
    end
  end

  test "Cannot place a student in a company with which they have not interviewed" do
    assert_empty Interview.where(student: students(:anita),
                                 company: companies(:freedom_inc))
    assert_empty Pairing.where(placement: placements(:empty), company: companies(:freedom_inc))
    pairing_data = {
      placement: placements(:empty),
      student: students(:anita),
      company: companies(:freedom_inc)
    }
    p = Pairing.new(pairing_data)
    assert_not p.valid?
    assert_includes p.errors.messages, :match
  end
end
