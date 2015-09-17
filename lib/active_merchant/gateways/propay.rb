require "propay"

module ActiveMerchant
  module Billing
    class ProPay < Gateway
      self.money_format = :cents
      self.default_currency = "USD"
      self.supported_cardtypes = [:visa, :master, :american_express, :discover, :diners_club, :jcb]
      self.homepage_url = "http://propay.com/"
      self.display_name = "ProPay"
      self.test_url = "https://protectpaytest.propay.com/api/sps.svc"
      self.live_url = "https://api.propay.com/protectpay/sps.svc"

      def initialize(options = {})
        requires!(options, :authentication_token, :biller_account_id)
        super
      end

      # Authorize payment.
      def authorize(money, paysource, options = {})
        requires!(options, :payer_id)
        options[:currency_code] ||= self.default_currency
        payment_method_id = obtain_payment_method(options[:payer_id], paysource)[:payment_method_id]
        options = options
                  .merge(billing_address)
                  .merge(@options)
                  .merge(:payment_method_id => payment_method_id, :amount => money)
        res = ::ProPay::Command::AuthorizePaymentMethodTransaction.new(options)
        wrap_response(res, payment_method_id)
      end

      # Capture the payment.
      #
      # Note: `authorization` is ignored because ProPay needs
      # either `original_transaction_id` or `transaction_history_id`, or both.
      # (You should supply these in the `options`).
      def capture(money, authorization, options = {})
        options = options.merge(@options).merge(:amount => money)
        res = ::ProPay::Command::CapturePayment.new(options)
        wrap_response(res, authorization)
      end

      # Purchase (authorize & capture in a single transaction).
      def purchase(money, paysource, options = {})
        requires!(options, :payer_id)
        options[:currency_code] ||= self.default_currency
        payment_method_id = obtain_payment_method(options[:payer_id], paysource)[:payment_method_id]
        options = options
                  .merge(billing_address)
                  .merge(@options)
                  .merge(:payment_method_id => payment_method_id, :amount => money)
        res = ::ProPay::Command::ProcessPaymentMethodTransaction.new(options)
        wrap_response(res, payment_method_id)
      end

      def credit(money, paysource, options = {})
        requires!(options, :payer_id)
        options[:currency_code] ||= self.default_currency
        payment_method_id = obtain_payment_method(options[:payer_id], paysource)[:payment_method_id]
        options = options
                  .merge(billing_address)
                  .merge(@options)
                  .merge(:payment_method_id => payment_method_id, :amount => money)
        res = ::ProPay::Command::CreditPayment.new(options)
        wrap_response(res, payment_method_id)
      end

      # Void the payment.
      #
      # Note: `authorization` is ignored because ProPay needs
      # either `original_transaction_id` or `transaction_history_id`, or both.
      # (You should supply these in the `options`).
      def void(authorization, options = {})
        res = ::ProPay::Command::VoidPayment.new(options.merge(@options))
        wrap_response(res, authorization)
      end

      # Refund the payment.
      #
      # Note: `authorization` is ignored because ProPay needs
      # either `original_transaction_id` or `transaction_history_id`, or both.
      # (You should supply these in the `options`).
      # Set `money` to 0 for a full refund or a custom value for a partial refund.
      def refund(money, authorization, options = {})
        res = ::ProPay::Command::RefundPayment.new(options.merge(@options).merge(:amount => money))
        wrap_response(res, authorization)
      end

      def recurring(money, creditcard, options = {})
        raise NotImplementedError, "TODO: #{__method__}"
      end

      # Setup (find or create) both payer and payment method.
      #
      # @options is a mix of payer and payment method options
      #
      # @returns Array [{...payer...}, {...payment_method...}]
      def setup(options = {})
        payer = setup_payer(options)
        payment_method = setup_payment_method(payer[:payer_id], options)
        [payer, payment_method]
      end

      # Find or create a new payer.
      def setup_payer(options = {})
        find_payers(options).first || create_payer(options)
      end

      # Find or create a new payment method.
      def setup_payment_method(payer_id, options = {})
        find_payment_methods(payer_id, options).first || create_payment_method(payer_id, options)
      end

      def find_payers(options = {})
        ::ProPay::Command::GetPayers.new(options.merge(@options)).payers
      end

      def create_payer(options = {})
        payer = ::ProPay::Command::CreatePayerWithData.new(options.merge(@options))
        { :external_id_1 => options[:external_id_1],
          :external_id_2 => options[:external_id_2],
          :name => options[:name] || @options[:name],
          :email => options[:email] || @options[:email],
          :payer_id => payer.payer_id
        }.reject {|_, v| v.nil? }
      end

      def delete_payer(payer_id)
        ::ProPay::Command::DeletePayer.new(@options.merge(:payer_id => payer_id)).execute
      end

      def edit_payer(payer_id, options = {})
        ::ProPay::Command::EditPayer.new(options.merge(@options).merge(:payer_id => payer_id)).execute
      end

      def find_payment_methods(payer_id, options = {})
        ::ProPay::Command::GetAllPayerPaymentMethods.new(options.merge(@options).merge(:payer_id => payer_id)).payment_methods
      end

      def create_payment_method(payer_id, options = {})
        options = options
                  .merge(billing_address)
                  .merge(@options)
                  .merge(:payer_id => payer_id)
        payment_method = ::ProPay::Command::CreatePaymentMethod.new(options)
        { :account_name => options[:account_name],
          :email => options[:email] || @options[:email],
          :description => options[:description],
          :expiration_date => options[:expiration_date],
          :payment_method_id => payment_method.payment_method_id,
          :payment_method_type => options[:payment_method_type],
          :priority => options[:priority],
          :protected => options[:protected]
        }.merge(billing_address).reject {|_, v| v.nil? }
      end

      def delete_payment_method(payer_id, payment_method_id)
        ::ProPay::Command::DeletePaymentMethod.new(@options.merge(:payment_method_id => payment_method_id, :payer_id => payer_id)).execute
      end

      def edit_payment_method(payer_id, payment_method_id, options = {})
        raise NotImplementedError, "TODO: #{__method__}"
      end

      def create_merchant_profile(profile_name, options = {})
        requires!(options, :payment_processor, :processor_data)
        res = ::ProPay::Command::CreateMerchantProfile.new(options.merge(@options).merge(:profile_name => profile_name))
        if res.success?
          res.merchant_profile_id
        else
          raise ::ProPay::StandardError, res.message
        end
      end

      # Mapping of ActiveMerchant billing address into ProPay billing address
      def billing_address
        return @billing_address if @billing_address

        @options[:billing_address] ||= {}

        @billing_address = {
          :address_1 => @options[:billing_address][:address_1],
          :address_2 => @options[:billing_address][:address_2],
          :city => @options[:billing_address][:city],
          :country => @options[:billing_address][:country] || "USA",
          :state => @options[:billing_address][:state],
          :telephone_number => @options[:billing_address][:phone],
          :zip_code => @options[:billing_address][:zip]
        }.reject {|_, v| v.nil? }
      end


      private

      def wrap_response(res, authorization = nil)
        ropts = {
          :authorization => authorization || res.transaction[:authorization_code],
          :avs_result => { :code => res.transaction[:avs_code] },
          :cvv_result => res.transaction[:cvv_response_code],
          :test => res.test?
        }
        ActiveMerchant::Billing::Response.new(res.success?, res.message, res.transaction, ropts)
      end

      def obtain_payment_method(payer_id, paysource)
        if paysource.is_a?(ActiveMerchant::Billing::CreditCard)
          options = payment_method_options_from_credit_card(payer_id, paysource)
          create_payment_method(payer_id, billing_address.merge(:email => @options[:email]).merge(options))
        elsif paysource.is_a?(Hash)
          create_payment_method(payer_id, billing_address.merge(:email => @options[:email]).merge(paysource))
        else
          {:payment_method_id => paysource}
        end
      end

      def payment_method_options_from_credit_card(payer_id, paysource)
        {
          :account_name => paysource.name,
          :account_number => paysource.number,
          :description => "Payment Method for #{payer_id}",
          :duplicate_action => "ReturnDup",
          :expiration_date => sprintf("%02d", paysource.expiry_date.month) + paysource.expiry_date.year.to_s[2,2],
          :payment_method_type => brand_remapping[paysource.brand] || "Visa"
        }
      end

      # Mapping of ActiveMerchant::Billing::CreditCard brands to ProPay brands
      def brand_remapping
        {
          'visa' => "Visa",
          'master' => "MasterCard",
          'discover' => "Discover",
          'american_express' => "AMEX",
          'diners_club' => "DinersClub",
          'jcb' => "JCB",
          'switch' => "Switch",
          'solo' => "Solo",
          'dankort' => "Dankort",
          'maestro' => "Maestro",
          'forbrugsforeningen' => "Forbrugsforeningen",
          'laser' => "Laser"
        }
      end
    end
  end
end
