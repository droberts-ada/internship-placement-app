require 'test_helper'

include Typeform

describe FormResponse do
  def typeform_id
    SecureRandom.base64(6)
  end

  let(:id) { SecureRandom.hex(32) }
  let(:form_id) { typeform_id }
  let(:definition) do {
    id: form_id,
    title: 'test form',
    fields: [
      field_text,
      field_multiple_choice,
    ],
  } end

  def field_text() {
    id: typeform_id,
    title: 'test text field',
    type: 'short_text',
    ref: SecureRandom.uuid,
    properties: {},
  } end

  def field_multiple_choice() {
    id: typeform_id,
    title: 'test multiple_choice field',
    type: 'multiple_choice',
    ref: SecureRandom.uuid,
    properties: {},
    choices: [
      { id: typeform_id, label: 'test choice label 1' },
      { id: typeform_id, label: 'test choice label 2' },
      { id: typeform_id, label: 'test choice label 3' },
    ],
  } end

  let(:answers_raw) do [
    answer_text(definition[:fields][0]),
    answer_choice(definition[:fields][1]),
  ] end

  def answers_hash(raw)
    raw.map { |a| [a[:field][:id], a.except(:field)] }.to_h
  end

  let(:answers) { answers_hash(answers_raw) }

  def answer_text(field) {
    type: 'text',
    text: 'test answer',
    field: field.slice(:id, :type, :ref),
  } end

  def answer_choice(field) {
    type: 'choice',
    choice: {
      label: field[:choices].sample[:label],
    },
    field: field.slice(:id, :type, :ref),
  } end

  let(:hidden) do {
    var_one: 'test hidden var_one',
  } end

  let(:response) { FormResponse.new(id, form_id, definition, answers, hidden) }

  describe 'constructor' do
    it 'sets the response id' do
      id = SecureRandom.hex(32)
      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.id).must_equal id
    end

    it 'sets the form id' do
      form_id = typeform_id
      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.form_id).must_equal form_id
    end

    it 'sets the definition' do
      definition = {id: typeform_id, title: 'another form', fields: [field_text]}
      answers = answers_hash([answer_text(definition[:fields][0])])

      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.definition).must_equal definition
    end

    it 'sets the answers' do
      definition = {id: typeform_id, title: 'another form', fields: [field_text]}
      answers = answers_hash([answer_text(definition[:fields][0])])

      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.answers).must_equal answers
    end

    it 'sets the form hidden variables' do
      hidden = {example_var: 'example value'}
      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.hidden).must_equal hidden
    end
  end

  describe '.from_webhook_event' do
    def event(name)
      path = Rails.root.join *(%w(test data typeform)+["#{name}.json"])
      request = JSON.load(File.open(path))
      WebhookEvent.from_params(request)
    end

    let(:event_good) { event(:webhook_req_good) }
    let(:event_bad) { event(:webhook_req_bad) }

    it 'returns a FormResponse instance' do
      result = FormResponse.from_webhook_event(event_good)

      expect(result).must_be_kind_of FormResponse
    end

    it 'raises FormResponseError for invalid event data' do
      expect {
        FormResponse.from_webhook_event(event_bad)
      }.must_raise FormResponseError
    end

    it 'sets the id from event data' do
      event_good.data[:token] = id

      result = FormResponse.from_webhook_event(event_good)

      expect(result.id).must_equal id
    end

    it 'sets the id from event data' do
      event_good.data[:token] = id

      result = FormResponse.from_webhook_event(event_good)

      expect(result.id).must_equal id
    end

    it 'sets the form id from event data' do
      event_good.data[:form_id] = form_id

      result = FormResponse.from_webhook_event(event_good)

      expect(result.form_id).must_equal form_id
    end

    it 'sets the form definition from event data' do
      # Must set both or the response will be invalid
      event_good.data[:definition] = definition
      event_good.data[:answers] = answers_raw

      result = FormResponse.from_webhook_event(event_good)

      expect(result.definition).must_equal definition
    end

    it 'sets the answers from event data' do
      # Must set both or the response will be invalid
      event_good.data[:definition] = definition
      event_good.data[:answers] = answers_raw

      result = FormResponse.from_webhook_event(event_good)

      answers_raw.each do |expected|
        field_id = expected[:field][:id]
        expect(result.answers.keys).must_include field_id

        actual = result.answers[field_id]
        expect(actual[:type]).must_equal expected[:type]

        case actual[:type]
        when 'text'
          # Text answers must match text value
          expect(actual[:text]).must_equal expected[:text]
        when 'choice'
          # The choice must reference a choice from the
          # definition for the matching field
          field = definition[:fields].find { |f| f[:id] == field_id }
          labels = field[:choices].map { |c| c[:label] }

          expect(labels).must_include actual[:choice][:label]
        else
          # All expected fields must match exactly
          expected.except(:field).keys.each do |key|
            expect(actual[key]).must_equal expected[key]
          end
        end
      end
    end

    it 'sets the hidden variables from event data' do
      event_good.data[:hidden] = hidden

      result = FormResponse.from_webhook_event(event_good)

      expect(result.hidden).must_equal hidden
    end
  end

  describe '#answer' do
    it 'returns the answer value for the given field' do
      field_id = definition[:fields][0][:id]
      result = response.answer(field_id)
      expect(result).must_equal answers_raw[0][:text]

      field_id = definition[:fields][1][:id]
      labels = definition[:fields][1][:choices].map { |c| c[:label] }
      expect(labels).must_include response.answer(field_id)
    end

    it 'returns nil for an invalid field ID' do
      field_id = definition[:fields].map { |f| f[:id] }.sum

      result = response.answer(field_id)

      expect(result).must_be_nil
    end
  end
end
