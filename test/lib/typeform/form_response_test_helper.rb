require 'active_support/concern'

module FormResponseTestHelper
  extend ActiveSupport::Concern

  included do
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
  end
end
