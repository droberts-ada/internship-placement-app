object @placement
attributes :id, :whiteboard
child :students do
  attributes :id, :name
  child :rankings do |ranking|
    attributes :student_preference, :interview_result, :score, :interview_result_reason, :company_id
  end
end
child :companies do
  attributes :id, :name, :slots
end
child :pairings do
  attributes :student_id, :company_id
end
