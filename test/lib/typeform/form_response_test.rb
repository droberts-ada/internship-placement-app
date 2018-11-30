require 'test_helper'

include Typeform

describe FormResponse do
  let(:id) { SecureRandom.hex(32) }
  let(:form_id) { SecureRandom.base64(6) }
  let(:definition) do {
    id: form_id,
    title: 'test form',
    fields: [field_text],
  } end

  def field_text() {
    id: SecureRandom.base64(6),
    title: 'test field',
    type: 'short_text',
    ref: SecureRandom.uuid,
    properties: {},
  } end

  let(:answers) do [
    answer_text(definition[:fields][0]),
  ] end

  def answer_text(field) {
    type: 'text',
    text: 'test answer',
    field: field.slice(:id, :type, :ref),
  } end

  let(:hidden) do {
    var_one: 'test hidden var_one',
  } end

  describe 'constructor' do
    it 'sets the response id' do
      id = SecureRandom.hex(32)
      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.id).must_equal id
    end

    it 'sets the form id' do
      form_id = SecureRandom.base64(6)
      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.form_id).must_equal form_id
    end

    it 'sets the definition' do
      definition = {id: SecureRandom.base64(6), title: 'another form', fields: [field_text]}
      result = FormResponse.new(id, form_id, definition, answers, hidden)
      expect(result.definition).must_equal definition
    end

    it 'sets the answers' do
      definition = {id: SecureRandom.base64(6), title: 'another form', fields: [field_text]}
      answers = [answer_text(definition[:fields][0])]
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
      event_good.data[:answers] = answers

      result = FormResponse.from_webhook_event(event_good)

      expect(result.definition).must_equal definition
    end

    it 'sets the answers from event data' do
      # Must set both or the response will be invalid
      event_good.data[:definition] = definition
      event_good.data[:answers] = answers

      result = FormResponse.from_webhook_event(event_good)

      answers.each do |expected|
        field_id = expected[:field][:id]
        expect(result.answers.keys).must_include field_id

        actual = result.answers[field_id]
        expected.except(:field).keys.each do |key|
          expect(actual[key]).must_equal expected[key]
        end
      end
    end

    it 'sets the hidden variables from event data' do
      event_good.data[:hidden] = hidden

      result = FormResponse.from_webhook_event(event_good)

      expect(result.hidden).must_equal hidden
    end
  end
end
