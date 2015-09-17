require "propay/command/base"

module ProPay
  module Command
    class CreatePaymentMethod < Base
      def initialize(params = {})
        super

        pmt = @params[:payment_method_type]

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].CreatePaymentMethod {
                xml["con"].identification {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].pmAdd {
                  xml["typ"].AccountCountryCode assert_valid_param(:account_country_code, @params, %w(USA CAN), %w(Checking Savings).include?(pmt))
                  xml["typ"].AccountName @params[:account_name] if @params[:account_name]
                  xml["typ"].AccountNumber @params[:account_number]
                  xml["typ"].BankNumber assert_valid_param(:bank_number, @params, [@params[:bank_number]], %w(Checking Savings).include?(pmt))
                  xml["typ"].BillingInformation {
                    xml["typ"].Address1 @params[:address_1] if @params[:address_1]
                    xml["typ"].Address2 @params[:address_2] if @params[:address_2]
                    xml["typ"].Address3 @params[:address_3] if @params[:address_3]
                    xml["typ"].City @params[:city] if @params[:city]
                    xml["typ"].Country assert_valid_param(:country, params, %w(USA CAN))
                    xml["typ"].Email @params[:email] if @params[:email]
                    xml["typ"].State @params[:state] if @params[:state]
                    xml["typ"].TelephoneNumber @params[:telephone_number] if @params[:telephone_number]
                    xml["typ"].ZipCode @params[:zip_code] if @params[:zip_code]
                  }
                  xml["typ"].Description @params[:description]
                  xml["typ"].DuplicateAction assert_valid_param(:duplicate_action, @params, %w(SaveNew Error ReturnDup))
                  xml["typ"].ExpirationDate @params[:expiration_date] if @params[:expiration_date]
                  xml["typ"].PayerAccountId @params[:payer_id]
                  xml["typ"].PaymentMethodType assert_valid_param(:payment_method_type, @params, %w(Visa MasterCard AMEX Discover DinersClub JCB ProPayToProPay Checking Savings), true)
                  xml["typ"].Priority @params[:priority] if @params[:priority]
                  xml["typ"].Protected @params[:protected].to_s if @params.has_key?(:protected)
                }
              }
            }
          }
        end
      end

      def payment_method_id
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:PaymentMethodId")
      end


      private

      def required_params
        [:authentication_token, :biller_account_id, :account_number, :description, :payer_id, :payment_method_type]
      end
    end
  end
end
