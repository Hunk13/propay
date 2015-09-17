require "propay/command/base"
require "digest/md5"
require "openssl"
require "base64"

module ProPay
  module Command
    class GetTempToken < Base
      def initialize(params = {})
        super

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].GetTempToken {
                xml["con"].tempTokenRequest {
                  # FIXME: Acquirer's bugs, as usual. All other requests except this one
                  # use "con:identification" in place of "typ:Identification".
                  # Naturally, http://propay.com/SPS/types does not exist and we cannot check the DTD.
                  xml["typ"].Identification {
                    xml["typ"].AuthenticationToken @params[:authentication_token]
                    xml["typ"].BillerAccountId @params[:biller_account_id]
                  }
                  xml["typ"].PayerInfo {
                    xml["typ"].Id @params[:payer_id]
                    xml["typ"].Name @params[:name]
                  }
                  xml["typ"].TokenProperties {
                    xml["typ"].DurationSeconds @params[:duration_seconds]
                  }
                }
              }
            }
          }
        end
      end

      # Returns a hash of parameters for the SPI form.
      #
      # @returns Hash
      def fields(params = {})
        ppt = params[:payment_process_type]
        {
          "AuthToken" => encrypt(auth_token),
          "PayerId" => encrypt(payer_id),
          "PaymentProcessType" => encrypt(assert_valid_param(:payment_process_type, params, %w(ACH CreditCard), true)),
          "ProcessMethod" => encrypt(assert_valid_param(:process_method, params, %w(AuthOnly Capture None), true)),
          "PaymentMethodStorageOption" => encrypt(assert_valid_param(:payment_method_storage_option, params, %w(Always OnSuccess None), true)),
          "PaymentTypeId" => assert_valid_param(:payment_type_id, params, %w(Visa MasterCard AMEX Discover DinersClub JCB), ppt == "CreditCard"),
          "CardNumber" => assert_valid_param(:card_number, params, [params[:card_number]], ppt == "CreditCard"),
          "ExpMonth" => assert_valid_param(:exp_month, params, [params[:exp_month]], ppt == "CreditCard") && sprintf("%02d", params[:exp_month]),
          "ExpYear" => assert_valid_param(:exp_year, params, [params[:exp_year]], ppt == "CreditCard") && sprintf("%02d", params[:exp_year]),
          "CVV" => params[:cvv],
          "CurrencyCode" => encrypt(assert_valid_param(:currency_code, params, [params[:currency_code]], params[:process_method] != "None")),
          "Amount" => encrypt(assert_valid_param(:amount, params, [params[:amount]], params[:process_method] != "None")),
          "BankAccountNumber" => assert_valid_param(:bank_account_number, params, [params[:bank_account_number]], ppt == "ACH"),
          "BankAccountType" => assert_valid_param(:bank_account_type, params, %w(Checking Savings), ppt == "ACH"),
          "BankName" => params[:bank_name],
          "BankCountryCode" => assert_valid_param(:bank_country_code, params, [params[:bank_country_code]], ppt == "ACH"),
          "NameOnBankAccount" => assert_valid_param(:name_on_bank_account, params, [params[:name_on_bank_account]], ppt == "ACH"),
          "RoutingNumber" => assert_valid_param(:routing_number, params, [params[:routing_number]], ppt == "ACH"),
          "StandardEntryClassCode" => encrypt(assert_valid_param(:standard_entry_class_code, params, %w(WEB TEL IAT CCD PPD), ppt == "ACH")),
          "CardHolderName" => params[:card_holder_name],
          "Address1" => params[:address_1],
          "Address2" => params[:address_2],
          "Address3" => params[:address_3],
          "City" => params[:city],
          "State" => params[:state],
          "PostalCode" => params[:postal_code],
          "Country" => params[:country],
          "InvoiceNumber" => encrypt(params[:invoice_number]),
          "echo" => encrypt(params[:echo]),
          "ReturnURL" => encrypt(assert_valid_param(:return_url, params, [params[:return_url]], true)),
          "CID" => credential_id,
          "ProfileId" => encrypt(params[:profile_id]),
          "Comment1" => encrypt(params[:comment_1]),
          "Comment2" => encrypt(params[:comment_2]),
          "Protected" => params[:protected].to_s,
          "SettingsCipher" => assert_valid_param(:settings_cipher, params, [params[:settings_cipher]], true)
        }.delete_if {|_, v| v.nil? || v =~ /^\s*$/ }
      end

      def auth_token
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:TempToken")
      end

      def credential_id
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:CredentialId")
      end

      def payer_id
        xml_text("/s:Envelope/s:Body/xmlns:#{response_name}Response/xmlns:#{response_name}Result/a:PayerId")
      end


      private

      def required_params
        [:authentication_token, :biller_account_id, :payer_id, :duration_seconds]
      end

      def encrypt(string)
        # Return nil if given nil, for convenience.
        return nil if string.nil?

        # Initialize the cipher just once, but reset its state
        # so that we could reuse it non-consecutively.
        if @cipher
          @cipher.reset
        else
          key = Digest::MD5.hexdigest(auth_token.encode(Encoding::UTF_8))
          @cipher = OpenSSL::Cipher::AES128.new(:CBC).encrypt
          @cipher.key = key
          @cipher.iv = key
        end
        value = @cipher.update(string.encode(Encoding::UTF_8)) + @cipher.final
        Base64.urlsafe_encode64(value)
      end
    end
  end
end
