class AddInterviewsPerSlotToClassrooms < ActiveRecord::Migration[5.0]
  def change
    add_column :classrooms, :interviews_per_slot, :integer, default: 6, null: false
  end
end
