require 'httpi'
require 'open3'
require 'httpi/adapter/openssl_gost/version'

module HTTPI
  module Adapter
    class OpensslGost < Base

      register :openssl_gost

      def initialize(request)
        @request = request
        @pubkey_path  = request.auth.ssl.cert_file
        @privkey_path = request.auth.ssl.cert_key_file
        @cacert_path = request.auth.ssl.ca_cert_file
      end

      attr_reader :client
      attr_accessor :pubkey_path
      attr_accessor :privkey_path
      attr_accessor :cacert_path

      def request(method)
        uri = @request.url
        cmd = "openssl s_client -engine gost -connect '#{uri.host}:#{uri.port}' -quiet"
        cmd += " -cert '#{pubkey_path}'"    if pubkey_path
        cmd += " -key '#{privkey_path}'"    if privkey_path
        cmd += " -CAfile '#{cacert_path}'"  if cacert_path

        # Prepare request
        req = "#{method.upcase} #{uri.request_uri} HTTP/1.1\r\n"
        headers = @request.headers.map{|k,v| "#{k}: #{v}\r\n" }.join
        # Set up Content-Length header if body present (HTTPI doesn't it for us)
        if @request.body and !@request.headers['Content-Length']
          headers += "Content-Length: #{@request.body.bytesize}\r\n"
        end
        # Add hostname header and explicitly close connection (we need command to exit immediately)
        headers += "Host: #{uri.host}\r\nConnection: close\r\n\r\n"
        req += headers
        req += "#{@request.body}\r\n\r\n"  if @request.body

        # Send request, get answer
        HTTPI.logger.debug "Connecting to server with command: #{cmd}"
        HTTPI.logger.debug "Sending request:\r\n#{req}"
        retries = 0
        begin
          raw_response, openssl_stderr, status = Open3.capture3(cmd, stdin_data: req, binmode: true)
        rescue Errno::EPIPE # Sometimes fails with no reason
          retry if retries+=1 < 3
        end

        # Check whether command finished correctly and prepare response
        if status.success?
          HTTPI.logger.debug "Received response:\r\n#{raw_response}"
          status_string, headers_and_body = raw_response.split("\r\n", 2)
          response_headers, response_body = headers_and_body.split("\r\n\r\n", 2)
          response_code = status_string.scan(/\d{3}/).first
          response_headers = Hash[response_headers.split("\r\n").map{|h| h.split(':', 2).map(&:strip) }]
          HTTPI::Response.new(response_code, response_headers, response_body)
        else
          HTTPI.logger.fatal "While connecting to server #{uri.host} with command: #{cmd}"
          HTTPI.logger.fatal "Command returned:\r\n#{status.inspect}"
          HTTPI.logger.fatal "STDERR is:\n#{openssl_stderr}"
          # OpenSSL's s_client always return 1 on fail, try to catch most common errors
          case openssl_stderr
            when /connect:errno=60/ then raise HTTPI::TimeoutError
            when /connect:errno=61/ then raise (HTTPI::Error.new).extend(HTTPI::ConnectionError) # Connection refused
            when /connect:errno=2/  then raise (HTTPI::Error.new).extend(HTTPI::ConnectionError) # No DNS name found
            when /ssl handshake failure/          then raise HTTPI::SSLError, 'Seems like you trying to connect to HTTP, not HTTPS'
            when /missing dsa signing cert/       then raise HTTPI::SSLError, 'Probably your OpenSSL lacks GOST configuration'
            when /unable to load certificate/     then raise HTTPI::SSLError, 'Can not load client certificate, check file path and access rights'
            when /unable to load .*? private key/ then raise HTTPI::SSLError, 'Can not load client certificate private key, check file path and access rights'
            else raise HTTPI::Error
          end
        end

      end

    end
  end
end
