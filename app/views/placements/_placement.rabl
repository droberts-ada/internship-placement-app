object @placement
attributes :id, :whiteboard
child :students do
  attributes :id, :name
  child :rankings do |ranking|
      attributes :student_preference, :interview_result, :company_id, :score
  end
  child :interviews do |interview|  
    child :interview_feedbacks do |feedback|
      attributes :interview_result, :result_explanation
    end
  end
end
child :companies do
  attributes :id, :name, :slots
end
child :pairings do
  attributes :student_id, :company_id
end
