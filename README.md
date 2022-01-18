# MSIDP::Endpoint

A simple library for authentication endpoints of Microsoft identity platform.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'msidp-endpoint'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install msidp-endpoint


## Getting started

### Preparation

Register your application.
See MS documents for details.

### Usage example
Client using OAuth 2.0 authorization code grant.
```ruby
require 'msidp/endpoint'

class Client
  include MSIDP::Endpoint

  def initialize
    @tenant = 'tentant.example.com'
    @auth_uri = authorize_uri(tenant)
    @token_uri = token_uri(tenant)
    @client_id = 'CLIENT-ID'
    @client_secret = 'CLIENT-SECRET'
    @redirect_uri = 'http://localhost/'
    @scope = 'https://graph.microsoft.com/.default'
  end

  def access_authorize_page
    params = {
      client_id: @client_id, response_type: 'code',
      redirect_uri: @redirect_uri, scope: @scope,
    }
    authorize(@auth_uri, params)
  end

  def get_token(code)
    @params = {
      code: code, client_id: @client_id, redirect_uri: @redirect_uri,
      grant_type: 'authorization_code', client_secret: @client_secret
    }
    call_token(@uri, @params)
  end
end

client = Client.new
response = client.access_authorize_page
# Get the code parameter of the query in the callback somehow.
token = client.get_token(code)

if token.valid? in: 3
  auth_header = { 'Authorization' => "Bearer #{token}" }

  # Request to a resource with the auth_header.
end
```


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
