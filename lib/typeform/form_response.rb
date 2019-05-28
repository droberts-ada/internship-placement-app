module Typeform
  class FormResponseError < StandardError; end

  class FormResponse
    attr_reader :id, :form_id, :definition, :answers, :hidden

    def initialize(id, form_id, definition, answers, hidden)
      @id = id
      @form_id = form_id
      @definition = definition
      @answers = answers
      @hidden = hidden
    end

    def answer(field_id)
      answer = answers[field_id]
      return if answer.blank?

      case answer[:type]
      when 'text'
        answer[:text]
      when 'choice'
        answer[:choice][:label]
      else
        raise FormResponseError.new("Unknown answer type: #{answer[:type]}")
      end
    end

    class << self
      def from_webhook_event(event)
        data = event.data
        id = data[:token]
        form_id = data[:form_id]
        definition = parse_definition(data[:definition])
        answers = parse_answers(definition, data[:answers])
        hidden = parse_hidden(data[:hidden])

        new(id, form_id, definition, answers, hidden)
      end

      private

      def parse_definition(data)
        data.slice(:id, :title)
            .merge(fields: data[:fields].map {|f| parse_field f})
      end

      def parse_field(data)
        data.slice(:id, :title, :type, :ref, :properties)
            .merge(
                case data[:type]
                when 'multiple_choice'
                  {choices: data[:choices].map {|c| parse_choice c}}
                else
                  {}
                end)
      end

      def parse_choice(data)
        data.slice(:id, :label)
      end

      def parse_answers(dfn, data)
        data.map {|a| parse_answer(dfn, a)}
            .map {|a| [a[:field][:id], a.except(:field)] }
            .to_h
      end

      def parse_answer(dfn, data)
        case data[:type]
        when 'text'
          parse_answer_text(dfn, data)
        when 'choice'
          parse_answer_choice(dfn, data)
        else
          raise FormResponseError.new("Unknown answer type: #{data[:type]}")
        end
      end

      def parse_answer_text(dfn, data)
        data.slice(:type, :text).merge(field: lookup_field(dfn, data[:field][:id]))
      end

      def parse_answer_choice(dfn, data)
        data.slice(:type).merge(
          choice: lookup_choice(dfn, data[:field][:id], data[:choice][:label]),
          field: lookup_field(dfn, data[:field][:id]),
        )
      end

      def lookup_field(dfn, id)
        field = dfn[:fields].find { |f| f[:id] == id }
        raise FormResponseError.new("Could not find field with id: #{id}") if field.nil?

        field
      end

      def lookup_choice(dfn, id, label)
        field = lookup_field(dfn, id)
        if field[:type] != 'multiple_choice'
          msg = "Looking up choice with label '#{label}' for " +
                "field(#{id}) that is not a multiple choice field"
          raise FormResponseError.new(msg)
        end

        choice = field[:choices].find { |c| c[:label] == label }
        if choice.nil?
          msg = "Could not find choice with label '#{label}' " +
                "for field(#{id})"
          raise FormResponseError.new(msg)
        end

        choice
      end

      def parse_hidden(data)
        data || {}
      end
    end
  end
end
