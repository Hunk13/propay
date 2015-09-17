require "propay/command/base"

module ProPay
  module Command
    class GetPayers < Base
      # Note: ProPay does not support searching by e-mail!
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].GetPayers {
                xml["con"].billerId {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].criteria {
                  xml["typ"].EmailAddress @params[:email] if @params[:email]
                  xml["typ"].ExternalId1 @params[:external_id_1] if @params[:external_id_1]
                  xml["typ"].ExternalId2 @params[:external_id_2] if @params[:external_id_2]
                  xml["typ"].Name @params[:name] if @params[:name]
                }
              }
            }
          }
        end
      end

      def payers
        path = "/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:Payers/a:PayerInfo"
        response.xpath(path, response.collect_namespaces).map do |payer|
          { :external_id_1 => payer.at("./a:ExternalId1", response.collect_namespaces).text,
            :external_id_2 => payer.at("./a:ExternalId2", response.collect_namespaces).text,
            :name => payer.at("./a:Name", response.collect_namespaces).text,
            :payer_id => payer.at("./a:payerAccountId", response.collect_namespaces).text }
            .reject {|_, v| v.empty? }
        end
      rescue NoMethodError
        raise ProPay::InvalidDataError, "cannot locate PayerInfo attributes"
      end

      private

      def required_params
        [:authentication_token, :biller_account_id]
      end
    end
  end
end
