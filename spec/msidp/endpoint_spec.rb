# frozen_string_literal: true

class Test
  extend MSIDP::Endpoint
end

RSpec.shared_context 'tenant' do
  let(:tenant) { 'tenant.example.com' }
end

RSpec.describe MSIDP::Endpoint, '#authorize_uri' do
  include_context 'tenant'
  subject { Test.authorize_uri(tenant) }
  it {
    is_expected.to eq URI.parse(
      "https://login.microsoftonline.com/#{tenant}/oauth2/v2.0/authorize"
    )
  }
end

RSpec.describe MSIDP::Endpoint, '#token_uri' do
  include_context 'tenant'
  subject { Test.token_uri(tenant) }
  it {
    is_expected.to eq URI.parse(
      "https://login.microsoftonline.com/#{tenant}/oauth2/v2.0/token"
    )
  }
end

RSpec.shared_context 'authorize uri' do
  include_context 'tenant'
  let(:uri) { Test.authorize_uri(tenant) }
end

RSpec.shared_context 'token uri' do
  include_context 'tenant'
  let(:uri) { Test.token_uri(tenant) }
end

RSpec.shared_context 'parameters' do
  let(:params) { { param: 'param' } }
end

RSpec.shared_context 'Net::HTTP mock' do
  let(:http) { instance_double(Net::HTTP) }
  before do
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http)
  end
end

RSpec.shared_context 'HTTP success response' do
  let(:response) do
    Net::HTTPOK.new(nil, 200, 'OK').tap do |res|
      res.content_type = res_contenttype
      allow(res).to receive(:body).and_return(res_body)
    end
  end
end

RSpec.shared_context 'HTTPOK response' do
  let(:res_body) { 'HTTP response body' }
  let(:res_contenttype) { 'text/plain' }
  include_context 'HTTP success response'
end

RSpec.shared_examples 'receiving HTTPOK response' do
  include_context 'Net::HTTP mock'
  include_context 'parameters'
  include_context 'HTTPOK response'
  it {
    expect(Net::HTTP).to receive(:start)
      .with(uri.host, uri.port, anything)
    expect(http).to receive(:request).with(
      have_attributes(path: path, body: body)
    )
    is_expected.to be_instance_of(Net::HTTPOK)
      .and have_attributes(code: 200, body: res_body)
  }
end

RSpec.describe MSIDP::Endpoint, '#get' do
  include_context 'authorize uri'
  subject { Test.get(uri, params) }
  include_examples 'receiving HTTPOK response' do
    let(:path) do
      uri.dup.tap { |u| u.query = URI.encode_www_form(params) }.request_uri
    end
    let(:body) { nil }
  end
end

RSpec.describe MSIDP::Endpoint, '#post' do
  include_context 'token uri'
  subject { Test.post(uri, params) }
  include_examples 'receiving HTTPOK response' do
    let(:path) { uri.request_uri }
    let(:body) { URI.encode_www_form(params) }
  end
end

RSpec.shared_context 'token response' do
  let(:token) { 'TOKEN' }
  let(:expires_in) { 3599 }
  let(:res_obj) do
    { token_type: 'Bearer', expires_in: expires_in, access_token: token }
  end
  let(:res_body) { JSON.dump(res_obj) }
  let(:res_contenttype) { 'application/json;' }
  let(:date) { Time.at(1234) }
  include_context 'HTTP success response'
  before do
    response['date'] = date.to_s
  end
end

RSpec.shared_context 'HTTP error response' do
  let(:error_code) { 'test_error' }
  let(:error_obj) { { error: error_code, error_description: 'Test Error' } }
  let(:response) do
    Net::HTTPBadRequest.new(nil, 400, 'Bad Request').tap do |res|
      res.content_type = 'application/json'
      allow(res).to receive(:body).and_return(JSON.dump(error_obj))
    end
  end
end

RSpec.shared_examples 'rising an error' do
  it {
    expect { subject }.to raise_error MSIDP::Error, &error_spec
  }
end

RSpec.shared_examples 'rising a hash error' do
  include_context 'HTTP error response'
  let(:error_spec) { ->(e) { expect(e.error).to eq error_code } }
  include_examples 'rising an error'
end

RSpec.shared_examples 'rising a text error' do
  include_context 'HTTPOK response'
  let(:error_spec) { ->(e) { expect(e.body).to eq res_body } }
  include_examples 'rising an error'
end

RSpec.describe MSIDP::Endpoint, '#validate_json_response' do
  subject { Test.validate_json_response(response) }
  context 'with a success response' do
    include_context 'token response'
    it { is_expected.to eq(response) }
  end
  context 'with an error response' do
    include_examples 'rising a hash error'
  end
  context 'with an invalid response' do
    include_examples 'rising a text error'
  end
end

RSpec.describe MSIDP::Endpoint, '#authorize' do
  include_context 'Net::HTTP mock'
  include_context 'authorize uri'
  include_context 'parameters'
  subject { Test.authorize(uri, params) }
  context 'with a success response' do
    include_context 'HTTPOK response'
    it {
      expect(Test).to receive(:get)
        .with(uri, params).and_call_original
      is_expected.to eq(response)
    }
  end
  context 'with an error response' do
    include_examples 'rising a hash error'
  end
end

RSpec.describe MSIDP::Endpoint, '#token' do
  include_context 'Net::HTTP mock'
  include_context 'token uri'
  let(:scope) { 'https://example.com/scope' }
  subject { Test.token(uri, { scope: scope }) }
  context 'with a success response' do
    include_context 'token response'
    it {
      expect(Test).to receive(:post)
        .with(uri, { scope: scope }).and_call_original
      is_expected.to be_instance_of(MSIDP::AccessToken)
        .and have_attributes(
          value: token, scope: [scope], expire: date + expires_in
        )
    }
  end
  context 'with an error response' do
    include_examples 'rising a hash error'
  end
  context 'with an invalid response' do
    include_examples 'rising a text error'
  end
end
