# frozen_string_literal: true

module MSIDP
  # Error from Microsoft identity platform.
  class Error < StandardError
    # @return [Net::HTTPResponse] the HTTP response
    attr_reader :response
    # @return [String, Hash] the parsed body of the HTTP response in JSON case,
    #   otherwise the raw body.
    attr_reader :body
    # @return [String] the error code
    attr_reader :error
    # @return [String] the error description
    attr_reader :description

    # @param [Net::HTTPResponse] response the HTTP response
    def initialize(response)
      @response = response
      if response.content_type&.start_with? 'application/json'
        @body = JSON.parse(response.body, symbolize_names: true)
        @error = @body[:error]
        @description = @body[:error_description]
        super(<<-"MSG"
          #{response.code}: #{response.message}
          #{@error}: #{@description}
        MSG
        )
      else
        @body = response.body
        super(<<-"MSG"
          #{response.code}: #{response.message}
          #{@body}
        MSG
        )
      end
    end
  end
end
