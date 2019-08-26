require 'test_helper'

# A describe that ends in Generator activates Rails magic
describe 'Generation of Classroom' do
  it "Doesn't duplicate students or companies" do
    # ClassroomGenerator.build_classroom

    # classroom = Classroom.last

    # student_names = classroom.students.map(&:name)
    # company_names = classroom.companies.map(&:name)

    # expect(student_names).must_equal student_names.uniq
    # expect(company_names).must_equal company_names.uniq
  end
end
