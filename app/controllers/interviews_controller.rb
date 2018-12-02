class InterviewsController < ApplicationController
  skip_before_action :require_login,
                     :verify_authenticity_token,
                     only: [:feedback]

  before_action :verify_typeform_secret,
                :ignore_test_requests,
                only: [:feedback]

  def feedback
    event = Typeform::WebhookEvent.from_params(webhook_event_params)
    response = Typeform::FormResponse.from_webhook_event(event)

    logger.info "Received Typeform form response for form #{response.form_id}: #{response.id}"

    feedback = InterviewFeedback.create_from_form_response(response)
    if !feedback.persisted?
      log_error(feedback.errors.full_messages)
      return head :bad_request
    end

    render plain: 'Success', status: :ok
  rescue ArgumentError, Typeform::FormResponseError => ex
    log_error(ex.backtrace.prepend(ex.message))

    head :bad_request
  rescue ActiveRecord::RecordNotFound => ex
    log_error(ex.backtrace.prepend(ex.message))

    head :not_found
  end

  private

  SECRET = ENV['TYPEFORM_SECRET']
  def verify_typeform_secret
    head :not_found if SECRET.blank? || SECRET != params[:typeform_secret]
  end

  def webhook_event_params
    params.to_unsafe_hash
  end

  # We have to check this before actually parsing the parameters
  # because unfortunately the test webhooks don't have the same structure
  # as the real requests! What a good idea!
  def ignore_test_requests
    event_id = params[:event_id]
    response_id = params.dig(:form_response, :token)

    # If we don't have this information, don't do anything
    # the rest of the controller will handle the error
    return unless event_id.present? && response_id.present?

    # This is just a heuristic, but real form responses seem to have completely different tokens
    # and test webhook requests have tokens that start off the same as the event ID
    head :no_content if event_id[0..5] == response_id[0..5]
  end

  def log_error(messages)
    logger.error messages.prepend('Interview Feedback error:')
                         .push('Request Data:', params.to_h.inspect)
                         .join($/)
  end
end
