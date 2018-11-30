module Typeform
  class WebhookEvent
    attr_reader :id, :type, :data

    def initialize(id, type, data)
      @id = id
      @type = type
      @data = data
    end

    def self.from_params(params)
      unless valid? params
        raise ArgumentError.new("Invalid Typeform Webhook Event data: #{params}")
      end

      id = params[:event_id]
      type = params[:event_type]
      data = params[type] # this works for form_response type at least...

      new(id, type, data)
    end

    private

    def self.valid?(params)
      params.present? &&
      params[:event_id].present? &&
      params[:event_type].present?
    end
  end
end
