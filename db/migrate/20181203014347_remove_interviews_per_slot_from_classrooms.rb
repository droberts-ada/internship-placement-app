class RemoveInterviewsPerSlotFromClassrooms < ActiveRecord::Migration[5.0]
  def change
    remove_column :classrooms, :interviews_per_slot, :integer, default: 6
  end
end
