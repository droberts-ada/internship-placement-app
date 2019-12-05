class CleanUpBadRankings < ActiveRecord::Migration[5.0]
  def change
    # These didn't work due to bad data in the earlier migration.
    # change_column :rankings, :interview_id, :integer, null: false
    # remove_column :rankings, :student_id
    # remove_column :rankings, :company_id
    # remove_column :rankings, :interview_result

    Ranking.where(interview: nil).each do |ranking|
      interview = Interview.find_by(student_id: ranking.student_id,
                                    company_id: ranking.company_id)
      if interview.nil?
        interview = Interview.create!(student_id: ranking.student_id,
                                      company_id: ranking.company_id,
                                      scheduled_at: Time.now + 1.second)
      end

      ranking.interview = interview
      ranking.student_preference = [1, [ranking.student_preference, 5].min].max
      ranking.save!
    end
  end
end
