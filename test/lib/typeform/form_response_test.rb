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
end
