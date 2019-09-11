class CreateCompanySurveys < ActiveRecord::Migration[5.0]
  def change
    enable_extension 'uuid-ossp' # => http://theworkaround.com/2015/06/12/using-uuids-in-rails.html#postgresql

    create_table :company_surveys do |t|
      t.uuid :uuid, default: "uuid_generate_v4()", null: false, index: {unique: true}
      t.references :classrooms, index: true, foreign_key: true
      # We have a structured and thorough on-boarding process planned
      t.integer :onboarding, null: false
      # Frequency of paired programming
      t.integer :pair_programming, null: false
      # How structured is the day to day?  Is this a ticket based team
      # or a team with more discovery/exploratory based development?
      t.integer :structure, null: false
      # Does this team have other developers from a non-traditional
      # background, such as code boot-camp graduates or other Adies?
      t.integer :diverse_bg, null: false
      # Intern work with other adies?
      t.integer :other_adies, null: false
      # How frequently do you expect the Adie Meet with their:
      # Mentor
      t.integer :meet_with_mentor, null: false
      # Team Lead
      t.integer :meet_with_lead, null: false
      # Manager
      t.integer :meet_with_manager, null: false
      # What mentorship experience does the mentor already have?
      t.integer :mentorship_experience, null: false
      # How old will this team be when the Adie joins?
      t.integer :team_age, null: false
      # How large is this team?
      t.integer :team_size, null: false
    end
  end
end
