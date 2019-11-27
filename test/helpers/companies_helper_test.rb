require "test_helper"

describe CompaniesHelper, :helper do
  describe "display_cell" do
    it "adds 'deleted' as a class if redirect_to is set" do
      company = Company.new(classroom: Classroom.first, name: "foo", redirect_to: Company.first.uuid)
      inner = "Hello"
      cell = display_cell(company, inner)


      expect(cell).must_include inner
      expect(cell).must_include "span"
      expect(cell).must_include "deleted"
    end

    it "wraps it in a span if a class is passed in" do
      company = Company.new(classroom: Classroom.first, name: "foo")
      inner = "Goodbye"
      cell = display_cell(company, inner, class: "blah")

      expect(cell).must_include inner
      expect(cell).must_include "span"
      expect(cell).wont_include "deleted"
    end

    it "doesn't add a span if there's no class" do
      company = Company.new(classroom: Classroom.first, name: "foo")
      inner = "Goodbye"
      cell = display_cell(company, inner)

      expect(cell).must_include inner
      expect(cell).wont_include "span"
      expect(cell).wont_include "deleted"
    end
  end
end
