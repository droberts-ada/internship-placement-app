class InterviewFeedback < ApplicationRecord
  belongs_to :interview

  validates :interviewer_name, :interview_result, :result_explanation, presence: true
  validates :interview_result, numericality: { integer_only: true, greater_than: 0, less_than: 6 }
  validates :interview_id, uniqueness: { message: "Feedback has already been submitted for that student."}

  def self.create_from_form_response(response)
    # Find the interview this feedback is for
    interview = interview_from_form_response(response)

    # Get the answers we care about as attributes
    attrs = ATTR_FIELD_MAP.map do |attr, field_id|
      [attr, response.answer(field_id)]
    end.to_h

    # Convert the interview_result attribute to be the actual result rather than label
    attrs.merge!(
      interview: interview,
      interview_result: result_from_label(attrs[:interview_result]),
    )

    create(attrs)
  end

  private

  def self.interview_from_form_response(response)
    interview_id = response.hidden[:interview_id]
    Interview.find(interview_id)
  end

  def self.result_from_label(label)
    index = RESULT_LABELS.index(label)
    return unless index

    index + 1
  end

  # These are hard-coded to this form: https://admin.typeform.com/form/ShDqf4/results
  ATTR_FIELD_MAP = {
    interviewer_name:      'g0LG7jhFRh6M',
    interview_result:      'BuEureg7qiIk',
    result_explanation:    'w70qGjgDk9Yn',
    feedback_technical:    'EpGHZdcijRkI',
    feedback_nontechnical: 'hcICqNUKVP9V',
  }

  # WARNING: The order of these determines the resulting score!
  RESULT_LABELS = [
    'This person is not likely to be successful on our team',
    'This person may struggle on our team',
    'This person may or may not be a good addition on our team',
    'This person could be successful on our team',
    'This person could be a great addition to our team',
  ]
end
