# frozen_string_literal: true

RSpec.shared_context 'access token information' do
  let!(:now) { Time.parse(Time.now.getgm.to_s) }
  let(:token) { 'TOKEN_STRING' }
  let(:expires_in) { 3599 }
  let(:scope) { 'https://example.com/scope' }
  let(:refresh_token) { 'REFRESH_TOKEN' }
  let(:id_token) { 'ID_TOKEN' }
  let(:token_type) { 'Bearer' }
end

RSpec.shared_context 'minimum access token' do
  include_context 'access token information'
  let(:token_hash) do
    { token_type: token_type, expires_in: expires_in, access_token: token }
  end
  let(:access_token) do
    MSIDP::AccessToken.new(token, now + expires_in, [scope])
  end
end

RSpec.shared_context 'full access token' do
  include_context 'access token information'
  let(:token_hash) do
    {
      token_type: token_type, expires_in: expires_in, access_token: token,
      scope: scope, refresh_token: refresh_token, id_token: id_token
    }
  end
  let(:access_token) do
    MSIDP::AccessToken.new(
      token, now + expires_in, [scope], refresh_token, id_token, token_type
    )
  end
end

RSpec.shared_context 'HTTP response' do
  let(:response) do
    Net::HTTPOK.new(nil, 200, 'OK').tap do |res|
      res.content_type = 'application/json;'
      res['date'] = date.to_s
      allow(res).to receive(:body).and_return(JSON.dump(token_hash))
    end
  end
end

RSpec.shared_context 'query string' do
  let(:response) { URI.encode_www_form(token_hash) }
end

RSpec.shared_examples 'AccessToken' do
  let(:attributes) do
    token_hash
      .reject { |k| %i[access_token scope expires_in token_type].include?(k) }
      .merge({ scope: [scope], value: token, type: 'Bearer' })
  end
  it { is_expected.to have_attributes(attributes) }
end

RSpec.describe MSIDP::AccessToken, '#initialize' do
  subject { access_token }
  context 'with minimum arguments' do
    include_context 'minimum access token'
    include_examples 'AccessToken'
  end
  context 'with full arguments' do
    include_context 'full access token'
    include_examples 'AccessToken'
  end
end

RSpec.describe MSIDP::AccessToken, '#parse' do
  let(:date) { now }
  context 'for a HTTP response' do
    include_context 'HTTP response'
    context 'with minimum attributes' do
      include_context 'minimum access token'
      subject { MSIDP::AccessToken.parse(response, scope: scope) }
      include_examples 'AccessToken'
    end
    context 'with full attributes' do
      include_context 'full access token'
      subject { MSIDP::AccessToken.parse(response) }
      include_examples 'AccessToken'
    end
  end
  context 'for a query string' do
    include_context 'query string'
    include_context 'full access token'
    subject { MSIDP::AccessToken.parse(response) }
    include_examples 'AccessToken'
  end
end

RSpec.describe MSIDP::AccessToken, '#to_s' do
  include_context 'minimum access token'
  subject { access_token.to_s }
  it { is_expected.to eq(token) }
end

RSpec.describe MSIDP::AccessToken, '#valid?' do
  include_context 'minimum access token'
  context 'with no keyword' do
    subject { access_token.valid? }
    it { is_expected.to be true }
  end
  context 'in a minute' do
    subject { access_token.valid? in: 60 }
    it { is_expected.to be true }
  end
  context 'in the expiration period' do
    subject { access_token.valid? in: expires_in }
    it { is_expected.to be false }
  end
end
