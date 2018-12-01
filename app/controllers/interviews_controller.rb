class InterviewsController < ApplicationController
  skip_before_action :require_login,
                     only: [:feedback]

  def feedback
    event = Typeform::WebhookEvent.from_params(webhook_event_params)
    response = Typeform::FormResponse.from_webhook_event(event)

    render plain: 'Success', status: :ok
  rescue ArgumentError, Typeform::FormResponseError
    head :bad_request
  end

  private

  def webhook_event_params
    params.to_unsafe_hash
  end
end
