module Typeform
  class WebhookEvent
    attr_reader :id, :type, :data

    def initialize(id, type, data)
      @id = id
      @type = type
      @data = data
    end
  end
end
