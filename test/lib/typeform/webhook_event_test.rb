require 'test_helper'

include Typeform

describe WebhookEvent do
  describe 'constructor' do
    let(:id) { SecureRandom.hex(32) }
    let(:type) { 'test_type' }
    let(:data) do
      { test_key: 'test_value' }.with_indifferent_access
    end

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
end
