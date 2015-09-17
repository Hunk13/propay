require "propay/command/base"

module ProPay
  module Command
    class AuthorizePaymentMethodTransaction < Base
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types", "xmlns:prop" => "http://schemas.datacontract.org/2004/07/Propay.Contracts.SPS.External") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].AuthorizePaymentMethodTransaction {
                xml["con"].id {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].transaction {
                  xml["typ"].Amount @params[:amount]
                  xml["typ"].Comment1 @params[:comment_1] if @params[:comment_1]
                  xml["typ"].Comment2 @params[:comment_2] if @params[:comment_2]
                  xml["typ"].CurrencyCode @params[:currency_code]
                  xml["typ"].InputIpAddress @params[:input_ip_address] if @params[:input_ip_address]
                  xml["typ"].Invoice @params[:invoice] if @params[:invoice]
                  xml["typ"].MerchantProfileId @params[:merchant_profile_id] if @params[:merchant_profile_id]
                  xml["typ"].PayerAccountId @params[:payer_id]
                  xml["typ"].SessionId @params[:session_id] if @params[:session_id]
                }
                xml["con"].paymentMethodID @params[:payment_method_id]
                xml["con"].optionalPaymentInfoOverrides {
                  xml["prop"].Ach {
                    xml["prop"].BankAccountType @params[:bank_account_type] if @params[:bank_account_type]
                    xml["prop"].SecCode @params[:sec_code] if @params[:sec_code]
                  }
                  xml["prop"].CreditCard {
                    xml["prop"].Billing {
                      xml["typ"].Address1 @params[:address_1] if @params[:address_1]
                      xml["typ"].Address2 @params[:address_2] if @params[:address_2]
                      xml["typ"].Address3 @params[:address_3] if @params[:address_3]
                      xml["typ"].City @params[:city] if @params[:city]
                      xml["typ"].Country @params[:country] if @params[:country]
                      xml["typ"].Email @params[:email] if @params[:email]
                      xml["typ"].State @params[:state] if @params[:state]
                      xml["typ"].TelephoneNumber @params[:telephone_number] if @params[:telephone_number]
                      xml["typ"].ZipCode @params[:zip_code] if @params[:zip_code]
                    }
                    xml["prop"].CVV @params[:cvv] if @params[:cvv]
                    xml["prop"].ExpirationDate @params[:expiration_date] if @params[:expiration_date]
                    xml["prop"].FullName @params[:full_name] if @params[:full_name]
                  }
                  xml["prop"].Payer {
                    xml["prop"].IpAddress @params[:ip_address] if @params[:ip_address]
                  }
                }
              }
            }
          }
        end
      end


      private

      def required_params
        [:authentication_token, :biller_account_id, :payer_id, :payment_method_id, :amount, :currency_code]
      end
    end
  end
end
