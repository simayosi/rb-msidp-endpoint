# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'msidp/error'
require 'msidp/access_token'

module MSIDP
  # Utility methods for Microsoft identity platform endpoints.
  module Endpoint
    # Returns the authorize endpoint URI object.
    #
    # @param [String] tenant a directory tenant in GUID or domain-name format.
    def authorize_uri(tenant)
      uri(tenant, 'authorize')
    end

    # Returns the token endpoint URI object.
    #
    # @param [String] tenant a directory tenant in GUID or domain-name format.
    def token_uri(tenant)
      uri(tenant, 'token')
    end

    # Returns an endpoint URI object.
    #
    # @param [String] tenant a directory tenant in GUID or domain-name format.
    # @param [String] endpoint an endpoint.
    def uri(tenant, endpoint)
      URI.parse(
        "https://login.microsoftonline.com/#{tenant}/oauth2/v2.0/#{endpoint}"
      )
    end

    # Call the authorize endpoint and returns the response.
    #
    # @param [URI::Generic] uri the endpoint URI.
    # @param [Hash] params parameters to the endpoint.
    # @return [Net::HTTPResponse] the endpoint response.
    def authorize(uri, params)
      get(uri, params)
    end

    # Call the token endpoint and returns an issued access token.
    #
    # @param [URI::Generic] uri the endpoint URI.
    # @param [Hash] params parameters to the endpoint.
    # @param [Hash] supplement supplemental attributres for the access token.
    # @return [AccessToken] the issued access token.
    def token(uri, params, supplement = {})
      res = validate_json_response post(uri, params)
      suppl = params.select { |k| k.intern == :scope }.merge(supplement)
      AccessToken.parse(res, suppl)
    end

    # Get with parameters from an endpoint and returns the response.
    #
    # @param [URI::Generic] uri the endpoint URI.
    # @param [Hash] params parameters to the endpoint.
    # @param [Hash] headers additional headers.
    # @return [Net::HTTPResponse] the endpoint response.
    def get(uri, params, headers = nil)
      req_uri = URI.parse(uri.request_uri)
      req_uri.query = URI.encode_www_form(params) if params
      req = Net::HTTP::Get.new(req_uri.to_s, headers)
      https_request(uri, req)
    end

    # Post parameters to an endpoint and returns the response.
    #
    # @param [URI::Generic] uri the endpoint URI.
    # @param [Hash] params parameters to the endpoint.
    # @param [Hash] headers additional headers.
    # @return [Net::HTTPResponse] the endpoint response.
    def post(uri, params, headers = nil)
      req = Net::HTTP::Post.new(uri.request_uri, headers)
      req.form_data = params if params
      https_request(uri, req)
    end

    # Validate a HTTP response supposed to have the JSON body.
    def validate_json_response(res)
      raise Error, res unless res.is_a? Net::HTTPSuccess
      raise Error, res unless res.content_type&.start_with? 'application/json'

      res
    end

    private

    def https_request(uri, req)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      min_version: OpenSSL::SSL::TLS1_2_VERSION) do |http|
        res = http.request(req)
        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          res
        else
          raise Error, res
        end
      end
    end
  end
end
