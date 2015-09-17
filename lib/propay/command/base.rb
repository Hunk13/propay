require "nokogiri"
require "net/http"

module ProPay
  module Command
    class Base
      ACTION_URL = "http://propay.com/SPS/contracts/SPSService/"

      attr_reader :request

      def initialize(params = {})
        @params = symbolize_keys(params)
        assert_params!(@params)
        @test = @params[:test] || false
      end

      def test?
        @test
      end

      def endpoint
        if test?
          "https://protectpaytest.propay.com/api/sps.svc"
        else
          "https://api.propay.com/protectpay/sps.svc"
        end
      end

      def spr_collection_page
        "https://protectpay.propay.com/pmi/spr.aspx"
      end

      # Return the response from ProPay server.
      # (Runs the request the first time it is called).
      def response
        @response ||= Nokogiri::XML.parse(run)
      end

      # Run the command and return its success status.
      def execute
        success?
      end

      # Success response?
      def success?
        code.zero?
      end

      # Response message
      def message
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:RequestResult/a:ResultMessage")
      end

      # Response value
      def value
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:RequestResult/a:ResultValue")
      end

      # Response code
      def code
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:RequestResult/a:ResultCode").to_i
      end

      def transaction
        path = "/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:Transaction"
        trn = response.at(path, response.collect_namespaces)
        if trn.children.empty?
          {}
        else
          { :avs_code => trn.at("./a:AVSCode", response.collect_namespaces).text,
            :authorization_code => trn.at("./a:AuthorizationCode", response.collect_namespaces).text,
            :currency_conversion_rate => trn.at("./a:CurrencyConversionRate", response.collect_namespaces).text,
            :currency_converted_amount => trn.at("./a:CurrencyConvertedAmount", response.collect_namespaces).text,
            :currency_converted_currency_code => trn.at("./a:CurrencyConvertedCurrencyCode", response.collect_namespaces).text,
            :result_code => {
              :result_code => trn.at("./a:ResultCode/a:ResultCode", response.collect_namespaces).text,
              :result_message => trn.at("./a:ResultCode/a:ResultMessage", response.collect_namespaces).text,
              :result_value => trn.at("./a:ResultCode/a:ResultValue", response.collect_namespaces).text
            },
            :transaction_history_id => trn.at("./a:TransactionHistoryId", response.collect_namespaces).text,
            :transaction_id => trn.at("./a:TransactionId", response.collect_namespaces).text,
            :transaction_result => trn.at("./a:TransactionResult", response.collect_namespaces).text,
            :cvv_response_code => trn.at("./a:CVVResponseCode", response.collect_namespaces).text
          }.reject {|_, v| v.empty? }
        end
      rescue NoMethodError
        raise ProPay::InvalidDataError, "cannot locate Transaction attributes"
      end

      def logger
        self.class.logger
      end

      def self.logger
        ProPay.logger
      end


      private

      # Send the request to the endpoint.
      # Returns the XML body of the success response.
      #
      # By default, allows at most 2 redirections.
      #
      # @raise ProPay::ServerError
      # @returns <String, nil>
      def run(redirects = 2, uri = nil)
        uri = URI.parse(uri || endpoint)
        req = Net::HTTP::Post.new(uri.path)
        req["SOAPAction"] = ACTION_URL + action_name
        req["Accept"] = "application/xml"
        req.body = @request.to_xml
        req.content_type = "text/xml"
        log_request(req)
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == "https") { |http| http.request(req) }
        if res.is_a?(Net::HTTPSuccess)
          log_response(res)
          res.body
        elsif res.is_a?(Net::HTTPRedirection) && redirects > 0
          logger.debug "[PROPAY] Redirected to #{res['location']}..."
          run redirects-1, res["location"]
        else
          logger.error "[PROPAY] Error #{res.code}: #{res.message}"
          raise ProPay::ServerError, "#{res.code} #{res.message}"
        end
      end

      def xml_text(path)
        response.at(path, response.collect_namespaces).text
      rescue NoMethodError
        tag = path.match(/[^:\/]+$/)[0]
        raise ProPay::InvalidDataError, "cannot locate #{tag}"
      end

      def assert_params!(params = {})
        missing_params = required_params - params.keys
        unless missing_params.empty?
          raise ArgumentError, "missing parameters: #{missing_params}"
        end
      end

      def assert_valid_param(name, params, valid_values, required = false)
        value = params[name]
        if required
          if value.nil? || value == ""
            raise ArgumentError, ":#{name} must be present"
          else
            if valid_values.include?(value)
              value
            else
              raise ArgumentError, ":#{name} must be either of #{valid_values}"
            end
          end
        else
          value
        end
      end

      def required_params
        []
      end

      def action_name
        self.class.name.split("::").last
      end

      def response_name
        self.class.name.split("::").last
      end

      def symbolize_keys(h)
        h.inject({}) do |sh, (k, v)|
          # do not symbolize keys recursively
          sh.update(k.to_sym => v)
        end
      end

      def log_request(req)
        logger.debug "[PROPAY] REQUEST"
        logger.debug "[PROPAY] Path: #{req.path}"
        logger.debug req.each_header.map {|k, v| "[PROPAY] Header: #{k}: #{v}"}.join("\n")
        logger.debug "[PROPAY] Body:"
        logger.debug req.body.sub(/(AccountNumber>)[^<]+(<)/, "\\1XXXXXXXXXXXXXXXX\\2")
      end

      def log_response(res)
        logger.debug "[PROPAY] RESPONSE (#{res.code} #{res.message})"
        logger.debug "[PROPAY] Body:"
        logger.debug res.body
      end
    end
  end
end
