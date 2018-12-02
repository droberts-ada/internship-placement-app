require 'test_helper'

include Typeform

describe WebhookEvent do
  let(:id) { SecureRandom.hex(32) }
  let(:type) { 'test_type' }
  let(:data) do
    { test_key: 'test_value' }
  end

  describe 'constructor' do
    it 'sets the event id' do
      id = SecureRandom.hex(32)
      result = WebhookEvent.new(id, type, data)
      expect(result.id).must_equal id
    end

    it 'sets the event type' do
      type = 'some_type'
      result = WebhookEvent.new(id, type, data)
      expect(result.type).must_equal type
    end

    it 'sets the event data' do
      data = { data: 'value' }
      result = WebhookEvent.new(id, type, data)
      expect(result.data).must_equal data
    end
  end

  describe '.from_params' do
    let(:params) do
      path = File.join fixture_path, %w(files typeform webhook_req_good.json)

      JSON.load(File.open(path))
    end

    it 'returns a WebhookEvent instance' do
      result = WebhookEvent.from_params(params)

      expect(result).must_be_kind_of WebhookEvent
    end

    it 'raises ArgumentError for invalid params data' do
      params['event_id'] = nil

      expect {
        WebhookEvent.from_params(params)
      }.must_raise ArgumentError
    end

    it 'sets the id from params' do
      params['event_id'] = id
      result = WebhookEvent.from_params(params)

      expect(result.id).must_equal id
    end

    it 'sets the type from params' do
      params['event_type'] = type
      result = WebhookEvent.from_params(params)

      expect(result.type).must_equal type
    end

    it 'sets the data from params' do
      type = params['event_type']
      params[type] = data

      result = WebhookEvent.from_params(params)

      expect(result.data).must_equal data
    end
  end
end
