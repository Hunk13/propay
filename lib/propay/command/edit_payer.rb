require "propay/command/base"

module ProPay
  module Command
    # Corresponds to "EditPayerV2" in the docs (v.3.1.0)
    class EditPayer < Base
      # NOTE:
      #   "EmailAddress" is filled with @params[:email]
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types", "xmlns:prop" => "http://schemas.datacontract.org/2004/07/Propay.Contracts.SPS.External") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].EditPayerV2 {
                xml["con"].identification {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].request {
                  xml["prop"].PayerAccountId @params[:payer_id]
                  xml["prop"].UpdatedData {
                    xml["typ"].EmailAddress @params[:email] if @params[:email]
                    xml["typ"].ExternalId1 @params[:external_id_1] if @params[:external_id_1]
                    xml["typ"].ExternalId2 @params[:external_id_2] if @params[:external_id_2]
                    xml["typ"].Name @params[:name] if @params[:name]
                  }
                }
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
        [:authentication_token, :biller_account_id, :payer_id]
      end

      def action_name
        "EditPayerV2"
      end

      def response_name
        "EditPayerV2"
      end
    end
  end
end
