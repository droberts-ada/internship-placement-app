require 'test_helper'

class RankingTest < ActiveSupport::TestCase
  test "Create ranking with student and company" do
    ranking_data = {
      student: students(:no_company),
      company: companies(:no_students),
      student_preference: 3,
      interview_result: 5
    }
    # create! throws on failure
    r = Ranking.create!(ranking_data)
  end

  test "Cannot create ranking without student" do
    ranking_data = {
      company: companies(:no_students),
      student_preference: 3,
      interview_result: 5
    }
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :student
  end

  test "Cannot create ranking without company" do
    ranking_data = {
      student: students(:no_company),
      student_preference: 3,
      interview_result: 5
    }
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :company
  end

  test "Cannot create ranking without student_preference" do
    ranking_data = {
      student: students(:no_company),
      company: companies(:no_students),
      interview_result: 5
    }
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :student_preference
  end

  test "Cannot create ranking without interview_result" do
    ranking_data = {
      student: students(:no_company),
      company: companies(:no_students),
      student_preference: 3
    }
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :interview_result
  end

  test "A student-company pair can have only one ranking" do
    template = Ranking.first
    r = Ranking.new(student: template.student,
                    company: template.company);
    assert_not r.valid?
    assert_includes r.errors.messages, :student
  end

  test "Student ranking must be positive integer" do
    ranking_data = {
      student: students(:no_company),
      company: companies(:no_students),
      interview_result: 4
    }

    # Not integer
    ranking_data[:student_preference] = 3.3
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :student_preference

    # Not number
    ranking_data[:student_preference] = 'foo bar'
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :student_preference

    # Under
    ranking_data[:student_preference] = 0
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :student_preference
  end

  test "Interview result must be integer, 0 < i <= 5" do
    ranking_data = {
      student: students(:no_company),
      company: companies(:no_students),
      student_preference: 4
    }

    # Not integer
    ranking_data[:interview_result] = 3.3
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :interview_result

    # Not number
    ranking_data[:interview_result] = 'foo bar'
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :interview_result

    # Under
    ranking_data[:interview_result] = 0
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :interview_result

    # Over
    ranking_data[:interview_result] = 6
    r = Ranking.create(ranking_data)
    assert_not r.valid?
    assert_includes r.errors.messages, :interview_result
  end
end
