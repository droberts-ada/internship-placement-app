class CreateInterviews < ActiveRecord::Migration[5.0]
  def change
    create_table :interviews do |t|
      t.references :student, foreign_key: true
      t.references :company, foreign_key: true

      t.datetime :scheduled_at

      t.timestamps
    end

    add_index :interviews, [:student_id, :company_id], unique: true
  end
end
