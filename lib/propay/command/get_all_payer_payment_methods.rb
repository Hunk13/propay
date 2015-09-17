require "propay/command/base"

module ProPay
  module Command
    class GetAllPayerPaymentMethods < Base
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].GetAllPayerPaymentMethods {
                xml["con"].billerIdentification {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].payerAccountId @params[:payer_id]
              }
            }
          }
        end
      end

      def payment_methods
        path = "/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:PaymentMethods/a:PaymentMethodInformation"
        response.xpath(path, response.collect_namespaces).map do |payment_method|
          { :account_name => payment_method.at("./a:AccountName", response.collect_namespaces).text,
            :address_1 => payment_method.at("./a:BillingInformation/a:Address1", response.collect_namespaces).text,
            :address_2 => payment_method.at("./a:BillingInformation/a:Address2", response.collect_namespaces).text,
            :address_3 => payment_method.at("./a:BillingInformation/a:Address3", response.collect_namespaces).text,
            :city => payment_method.at("./a:BillingInformation/a:City", response.collect_namespaces).text,
            :country => payment_method.at("./a:BillingInformation/a:Country", response.collect_namespaces).text,
            :email => payment_method.at("./a:BillingInformation/a:Email", response.collect_namespaces).text,
            :state => payment_method.at("./a:BillingInformation/a:State", response.collect_namespaces).text,
            :telephone_number => payment_method.at("./a:BillingInformation/a:TelephoneNumber", response.collect_namespaces).text,
            :zip_code => payment_method.at("./a:BillingInformation/a:ZipCode", response.collect_namespaces).text,
            :date_created => payment_method.at("./a:DateCreated", response.collect_namespaces).text,
            :description => payment_method.at("./a:Description", response.collect_namespaces).text,
            :expiration_date => payment_method.at("./a:ExpirationDate", response.collect_namespaces).text,
            :obfuscated_account_number => payment_method.at("./a:ObfuscatedAccountNumber", response.collect_namespaces).text,
            :payment_method_id => payment_method.at("./a:PaymentMethodID", response.collect_namespaces).text,
            :payment_method_type => payment_method.at("./a:PaymentMethodType", response.collect_namespaces).text,
            :priority => payment_method.at("./a:Priority", response.collect_namespaces).text,
            :protected => payment_method.at("./a:Protected", response.collect_namespaces).text
          }.reject {|_, v| v.empty? }
        end
      rescue NoMethodError
        raise ProPay::InvalidDataError, "cannot locate PaymentMethod attributes"
      end

      private

      def required_params
        [:authentication_token, :biller_account_id, :payer_id]
      end
    end
  end
end
