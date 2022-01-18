# frozen_string_literal: true

RSpec.shared_context 'json response' do
  let(:error_code) { 'test_error' }
  let(:error_desc) { 'Test Error' }
  let(:error_obj) { { error: error_code, error_description: error_desc } }
  let(:response) do
    Net::HTTPBadRequest.new(nil, 400, 'Bad Request').tap do |res|
      res.content_type = 'application/json'
      allow(res).to receive(:body).and_return(JSON.dump(error_obj))
    end
  end
end

RSpec.shared_context 'text response' do
  let(:error_body) { 'Invalid Error!' }
  let(:response) do
    Net::HTTPBadRequest.new(nil, 400, 'Bad Request').tap do |res|
      allow(res).to receive(:body).and_return(error_body)
    end
  end
end

RSpec.describe MSIDP::Error do
  context 'with a json response' do
    include_context 'json response'
    subject { MSIDP::Error.new(response) }
    it {
      is_expected.to have_attributes(
        response: response, body: error_obj,
        error: error_code, description: error_desc
      )
    }
  end
  context 'with a text response' do
    include_context 'text response'
    subject { MSIDP::Error.new(response) }
    it {
      is_expected.to have_attributes(
        response: response, body: error_body,
        error: nil, description: nil
      )
    }
  end
end
