class CleanUpBadRankings < ActiveRecord::Migration[5.0]
  def change
    # These didn't work due to bad data in the earlier migration.
    # change_column :rankings, :interview_id, :integer, null: false
    # remove_column :rankings, :student_id
    # remove_column :rankings, :company_id
    # remove_column :rankings, :interview_result

    Ranking.all.each do |ranking|
      if ranking.interview.nil?
        interview = Interview.find_by(student_id: ranking.student_id,
                                      company_id: ranking.company_id)
        unless interview
          interview = Interview.create!(student_id: ranking.student_id,
                                        company_id: ranking.company_id,
                                        scheduled_at: Time.now + 1.second)
        end

        ranking.interview = interview
        ranking.save
      end
    end

    change_column :rankings, :interview_id, :integer, null: false
    remove_column :Ranking.firsts, :student_id if Ranking.first.respond_to? :student_id
    remove_column :Ranking.firsts, :company_id if Ranking.first.respond_to? :company_id
    remove_column :Ranking.firsts, :interview_result if Ranking.first.respond_to? :interview_result
  end
end
