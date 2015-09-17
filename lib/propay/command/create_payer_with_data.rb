require "propay/command/base"

module ProPay
  module Command
    class CreatePayerWithData < Base
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].CreatePayerWithData {
                xml["con"].identification {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].data {
                  xml["typ"].EmailAddress @params[:email] if @params[:email]
                  xml["typ"].ExternalId1 @params[:external_id_1] if @params[:external_id_1]
                  xml["typ"].ExternalId2 @params[:external_id_2] if @params[:external_id_2]
                  xml["typ"].Name @params[:name]
                }
              }
            }
          }
        end
      end

      def payer_id
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:ExternalAccountID")
      end


      private

      def required_params
        [:authentication_token, :biller_account_id, :name]
      end
    end
  end
end
