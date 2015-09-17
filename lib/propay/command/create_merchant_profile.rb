require "propay/command/base"

module ProPay
  module Command
    class CreateMerchantProfile < Base
      def initialize(params = {})
        super

        processor_data = @params[:processor_data] || {}

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types", "xmlns:prop" => "http://schemas.datacontract.org/2004/07/Propay.Contracts.SPS.External") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].CreateMerchantProfile {
                xml["con"].identification {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].merchantProfile {
                  xml["prop"].PaymentProcessor @params[:payment_processor]
                  xml["prop"].ProcessorData {
                    processor_data.each do |p_field, p_value|
                      xml["prop"].ProcessorDatum {
                        xml["prop"].ProcessorField p_field
                        xml["prop"].Value p_value
                      }
                    end
                  }
                  xml["prop"].ProfileName @params[:profile_name]
                }
              }
            }
          }
        end
      end

      def merchant_profile_id
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:ProfileId")
      end

      # OVERRIDING `message`, `value` and `code` because
      # they have different namespace for the terminals only for this command.
      # Consistency ftw!

      def message
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:RequestResult/b:ResultMessage")
      end

      def value
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:RequestResult/b:ResultValue")
      end

      def code
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:RequestResult/b:ResultCode").to_i
      end


      private

      def required_params
        [:authentication_token, :biller_account_id, :payment_processor, :profile_name]
      end
    end
  end
end
