module Typeform
  class FormResponse
    attr_reader :id, :form_id, :definition, :answers, :hidden

    def initialize(id, form_id, definition, answers, hidden)
      @id = id
      @form_id = form_id
      @definition = definition
      @answers = answers
      @hidden = hidden
    end
  end
end
