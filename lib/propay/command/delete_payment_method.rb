require "propay/command/base"

module ProPay
  module Command
    class DeletePaymentMethod < Base
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].DeletePaymentMethod {
                xml["con"].identification {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].payerAccountId @params[:payer_id]
                xml["con"].paymentID @params[:payment_method_id]
              }
            }
          }
        end
      end

      def message
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:ResultMessage")
      end

      def value
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:ResultValue")
      end

      def code
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:ResultCode").to_i
      end


      private

      def required_params
        [:authentication_token, :biller_account_id, :payer_id, :payment_method_id]
      end
    end
  end
end
