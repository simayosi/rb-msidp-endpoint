# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'json'

module MSIDP
  # Certificate credential for application authentication
  class CertificateCredential
    # @return [String] tenant a directory tenant in GUID or domain-name format.
    attr_accessor :tenant
    # @return [String] client_id the assigned applicaiton (client) ID.
    attr_accessor :client_id

    # Initialize an instance
    #
    # @param [OpenSSL::X509::Certificate] cert a certificate.
    # @param [OpenSSL::PKey] cert the private key paired with the certificate.
    # @param [String] tenant a directory tenant in GUID or domain-name format.
    # @param [String] client_id the assigned applicaiton (client) ID.
    def initialize(cert, key, tenant:, client_id:)
      @cert = cert
      @key = key
      @tenant = tenant
      @client_id = client_id
    end

    # Computes the JWT assertion.
    #
    # @return [String] JWT assertion string.
    def assertion
      header_base64 = base64url_encode(header)
      payload_base64 = base64url_encode(payload)
      signature = @key.sign('sha256', "#{header_base64}.#{payload_base64}")
      sign_base64 = base64url_encode(signature)
      "#{header_base64}.#{payload_base64}.#{sign_base64}"
    end

    # JOSE header of the JWT.
    #
    # @return [String] JSON string of the JOSE header.
    def header
      digest = OpenSSL::Digest::SHA1.digest(@cert.to_der)
      x5t = Base64.urlsafe_encode64(digest)
      header = { alg: 'RS256', typ: 'JWT', x5t: x5t.to_s }
      JSON.dump(header)
    end

    # JWS payload of the JWT claim.
    #
    # @return [String] JSON string of the JWS payload.
    def payload
      not_after = @cert.not_after.to_i
      not_before = @cert.not_before.to_i
      jti = make_jwt_id
      payload = {
        aud: "https://login.microsoftonline.com/#{tenant}/v2.0",
        exp: not_after, iss: client_id, jti: jti,
        nbf: not_after, sub: client_id, iat: not_before
      }
      JSON.dump(payload)
    end

    private

    def base64url_encode(data)
      Base64.urlsafe_encode64(data, padding: false)
    end

    def make_jwt_id
      data = @cert.to_der
      data << tenant
      data << client_id
      sha1hash_uuid(OpenSSL::Digest::SHA1.digest(data))
    end

    # rubocop:disable Style/FormatStringToken
    def sha1hash_uuid(hash)
      bytes = hash.bytes[0..15]
      bytes[6] = bytes[6] & 0x0F | 0x50
      bytes[8] = bytes[6] & 0x3F | 0x80
      format(
        '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x',
        *bytes
      )
    end
    # rubocop:enable Style/FormatStringToken
  end
end
