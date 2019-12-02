class AddScheduledAtTimezoneToInterviews < ActiveRecord::Migration[5.0]
  def change
    change_column :interviews, :scheduled_at, 'timestamp with time zone', using: "scheduled_at at time zone 'America/Los_Angeles'"
  end
end
