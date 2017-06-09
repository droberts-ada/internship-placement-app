require 'test_helper'

class UserTest < ActiveSupport::TestCase
  describe "validations" do
    it "works with valid data" do
      user = User.new(name: "Ada Lovelace", email: "ada@adadevelopersacademy.org")
      user.must_be :valid?
    end

    it "requires a name" do
      user = User.new(email: "ada@adadevelopersacademy.org")
      user.wont_be :valid?
      user.errors.messages.must_include :name
    end

    it "requires an email" do
      user = User.new(name: "Ada Lovelace")
      user.wont_be :valid?
      user.errors.messages.must_include :email
    end

    it "requires a valid email" do
      user = User.new(name: "Ada Lovelace", email: "@adadevelopersacademy.org")
      user.wont_be :valid?
      user.errors.messages.must_include :email
    end

    it "requires an @adadevelopersacademy.org email" do
      user = User.new(name: "Ada Lovelace", email: "bogus@gmail.com")
      user.wont_be :valid?
      user.errors.messages.must_include :email
    end
  end
end
