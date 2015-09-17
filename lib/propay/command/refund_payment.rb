require "propay/command/base"

module ProPay
  module Command
    class RefundPayment < Base
      def initialize(params = {})
        super

        unless @params[:original_transaction_id] || @params[:transaction_history_id]
          raise ArgumentError, "missing parameters: original_transaction_id or transaction_history_id"
        end

        @request = Nokogiri::XML::Builder.new do |xml|
          xml["soapenv"].Envelope("xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:con" => "http://propay.com/SPS/contracts", "xmlns:typ" => "http://propay.com/SPS/types", "xmlns:prop" => "http://schemas.datacontract.org/2004/07/Propay.Contracts.SPS.External") {
            xml["soapenv"].Header
            xml["soapenv"].Body {
              xml["con"].RefundPaymentV2 {
                xml["con"].id {
                  xml["typ"].AuthenticationToken @params[:authentication_token]
                  xml["typ"].BillerAccountId @params[:biller_account_id]
                }
                xml["con"].request {
                  xml["prop"].Amount @params[:amount]
                  xml["prop"].Comment1 @params[:comment_1] if @params[:comment_1]
                  xml["prop"].Comment2 @params[:comment_2] if @params[:comment_2]
                  xml["prop"].MerchantProfileId @params[:merchant_profile_id] if @params[:merchant_profile_id]
                  xml["prop"].OriginalTransactionId @params[:original_transaction_id] if @params[:original_transaction_id]
                  xml["prop"].TransactionHistoryId @params[:transaction_history_id] if @params[:transaction_history_id]
                }
              }
            }
          }
        end
      end


      private

      def required_params
        [:authentication_token, :biller_account_id]
      end

      def action_name
        "RefundPaymentV2"
      end

      def response_name
        "RefundPaymentV2"
      end
    end
  end
end
