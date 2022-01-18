# frozen_string_literal: true

require 'time'
require 'uri'
require 'net/http'
require 'json'

module MSIDP
  # Access token issued by Microsoft identity platform.
  class AccessToken
    # @return [String] the token string
    attr_reader :value
    # @return [Date] the expiration date
    attr_reader :expire
    # @return [Array] the scope, a list of permissions.
    attr_reader :scope
    # @return [String] the refresh token (optional)
    attr_reader :refresh_token
    # @return [String] the id token (optional)
    attr_reader :id_token
    # @return [String] the type
    attr_reader :type

    # Creates a new access token.
    #
    # @param [String] value the access token string.
    # @param [Date] expire the expiration date.
    # @param [Array] scope the list of permissions.
    # @param [String] refresh_token the refresh token.
    # @param [String] id_token the id token.
    # @param [String] type the token type.
    def initialize( # rubocop:disable Metrics/ParameterLists
      value, expire, scope,
      refresh_token = nil, id_token = nil, type = 'Bearer'
    )
      @value = value
      @scope = scope
      @expire = expire
      @refresh_token = refresh_token
      @id_token = id_token
      @type = type
    end

    # Parses a response from the endpoint and creates an access token object.
    #
    # @param [String,Net::HTTPResponse] res a query string or a HTTP respone.
    # @param [Hash] supplement attributes supplementary to the response.
    def self.parse(res, supplement = {}) # rubocop:disable Metrics/AbcSize
      case res
      when String
        hash = Hash[URI.decode_www_form(res)]
        date = Time.now - 1
      when Net::HTTPResponse
        hash = JSON.parse(res.body)
        date = res.key?('date') ? Time.parse(res['date']) : (Time.now - 1)
      else
        raise TypeError, 'expected String or Net::HTTPResponse'
      end
      hash = supplement.transform_keys(&:to_s).merge(hash)
      AccessToken.new(
        hash['access_token'], date + hash['expires_in'].to_i,
        hash['scope'].split(' '),
        hash['refresh_token'], hash['id_token'],
        hash['token_type']
      )
    end

    # Checks if the token is not expired.
    #
    # @option kwd [Integer] :in the number of seconds to offset.
    #
    # @example
    #     token.valid? in: 5
    def valid?(**kwd)
      @expire > Time.now + kwd.fetch(:in, 0)
    end

    def to_s
      @value
    end
  end
end
