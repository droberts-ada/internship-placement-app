class Classroom < ApplicationRecord
  has_many :students
  has_many :rankings, through: :students
  has_many :companies
  has_many :placements
  has_many :pairings, through: :placements
  belongs_to :creator, class_name: "User"

  # WARNING: extremely destructive!!!
  def purge()
    self.placements.each do |p|
      p.pairings.destroy_all
    end
    self.placements.destroy_all
    self.students.each do |s|
      s.rankings.destroy_all
    end
    self.companies.destroy_all
    self.students.destroy_all
  end

  def from_spreadsheets(interview_results, student_preferences)
    errors = []

    if interview_results.keys.sort != student_preferences.keys.sort
      raise Spreadsheet::SpreadsheetError("Mismatch in students between interview results and student_preferences")
    end

    # Transactions rollback on exceptions, so we need to
    # use the bang (!) versions of DB methods
    self.transaction do
      self.purge()

      # Build student records
      student_names = interview_results.keys

      student_names.each do |name|
        self.students.create!(name: name)
      end

      # Build company records
      company_names = []
      interview_results.each do |student_name, interviews|
        interviews.each do |company_name, results|
          company_names << company_name
        end
      end
      company_names.uniq!

      company_names.each do |name|
        self.companies.create!(name: name)
      end

      # Build ranking records
      student_names.each do |student_name|
        student = self.students.find_by(name: student_name)
        interviews = interview_results[student_name]
        preferences = student_preferences[student_name]

        if interviews.keys.sort != preferences.keys.sort
          errors << "Student #{student_name} has mismatch between interview companies #{interviews.keys} and preference companies #{preferences.keys}"
          next
        end

        interviews.keys.each do |company_name|
          company = self.companies.find_by(name: company_name)
          interview = interviews[company_name]
          preference = preferences[company_name]
          Ranking.create!(
            student: student,
            company: company,
            interview_result: interview['score'],
            interview_result_reason: interview['reason'],
            student_preference: preference)
        end
      end

      # Figure out how many internship slots each company has
      self.companies.each do |company|
        company.slots = company.rankings.count / (self.interviews_per_slot + 1) + 1
        puts "Company #{company.name} had #{company.rankings.count} interviews -> #{company.slots} slots"
        company.save!
      end

      if errors.length > 0
        error_text = "Encountered errors while building classroom records:"
        errors.each do |error|
          error_text += "\n" + error
        end
        raise Spreadsheet::SpreadsheetError.new(error_text)
      end
    end
  end
end
