class InterviewsController < ApplicationController
  skip_before_action :require_login,
                     only: [:feedback]

  before_action :verify_typeform_secret,
                only: [:feedback]

  def feedback
    event = Typeform::WebhookEvent.from_params(webhook_event_params)
    response = Typeform::FormResponse.from_webhook_event(event)

    logger.info "Received Typeform form response for form #{response.form_id}: #{response.id}"

    render plain: 'Success', status: :ok
  rescue ArgumentError, Typeform::FormResponseError => ex
    log_error(ex.backtrace.prepend(ex.message))

    head :bad_request
  end

  private

  SECRET = ENV['TYPEFORM_SECRET']
  def verify_typeform_secret
    head :not_found if SECRET.blank? || SECRET != params[:typeform_secret]
  end

  def webhook_event_params
    params.to_unsafe_hash
  end

  def log_error(messages)
    logger.error messages.prepend('Interview Feedback error:')
                         .push('Request Data:', params.to_h.inspect)
                         .join($/)
  end
end
