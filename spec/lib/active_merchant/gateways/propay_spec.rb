require "spec_helper"

describe ActiveMerchant::Billing::ProPay do
  let(:gateway) { described_class.new(gateway_options) }
  let(:gateway_options) { {:authentication_token => "4c9f4d70-a741-46c6-b1ed-e36432fea8e9", :biller_account_id => "8289197407827230", :test => true} }

  before do
    # clean-up
    gateway.find_payers(:external_id_2 => "2").each do |payer|
      gateway.delete_payer(payer[:payer_id])
    end
  end

  describe "integration" do
    describe "create_payer -> find_payers -> edit_payer -> delete_payer" do
      it "successfully passes" do
        payer = gateway.create_payer(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :email => "john.doe@nowhere.net")
        expect(payer[:payer_id]).not_to be_blank

        payers = gateway.find_payers(:external_id_2 => "2")
        expect(payers.last).to eq(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :payer_id => payer[:payer_id])

        expect(gateway.edit_payer(payer[:payer_id], :name => "Robin Hood")).to be_truthy
        payers = gateway.find_payers(:external_id_2 => "2")
        expect(payers.last).to eq(:external_id_1 => "1", :external_id_2 => "2", :name => "Robin Hood", :payer_id => payer[:payer_id])

        expect(gateway.delete_payer(payer[:payer_id])).to be_truthy
        expect(gateway.find_payers(:external_id_2 => "2")).to be_empty
      end
    end

    describe "create_payer -> create_payment_method -> find_payment_methods -> edit_payment_method -> delete_payment_method" do
      it "successfully passes" do
        payer = gateway.create_payer(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :email => "john.doe@nowhere.net")

        pm = gateway.create_payment_method(payer[:payer_id], :account_number => "4111111111111111", :description => "test credit card", :payment_method_type => "Visa")
        expect(pm[:payment_method_id]).not_to be_blank

        pms = gateway.find_payment_methods(payer[:payer_id])
        expect(pms.last[:payment_method_id]).to eq pm[:payment_method_id]

        # TODO: pending edit_payment_method implementation

        expect(gateway.delete_payment_method(payer[:payer_id], pm[:payment_method_id])).to be_truthy
        expect(gateway.find_payment_methods(payer[:payer_id])).to be_empty
      end
    end

    describe "setup -> authorize -> capture -> refund" do
      it "successfully passes" do
        exp_date = Date.today + 365

        payer, payment_method = gateway.setup(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :email => "john.doe@nowhere.net", :account_number => "4111111111111111", :description => "test credit card", :payment_method_type => "Visa", :country => "USA", :expiration_date => exp_date.strftime("%m%y"))
        expect(payer[:payer_id]).not_to be_blank
        expect(payment_method[:payment_method_id]).not_to be_blank

        res = gateway.authorize("350", payment_method[:payment_method_id], :payer_id => payer[:payer_id])
        expect(res).to be_success
        expect(res.authorization).not_to be_blank
        expect(res.params).not_to be_empty
        expect(res.params["transaction_history_id"]).not_to be_blank
        expect(res.params["transaction_id"]).not_to be_blank

        auth = res.authorization
        extra_auth = {
          :transaction_history_id => res.params["transaction_history_id"],
          :original_transaction_id => res.params["transaction_id"]
        }

        res = gateway.capture("350", auth, extra_auth)
        expect(res).to be_success
        expect(res.params).not_to be_empty
        expect(res.params["transaction_history_id"]).not_to be_blank
        expect(res.params["transaction_id"]).not_to be_blank

        res = gateway.refund(0, auth, extra_auth)
        expect(res).to be_success
        expect(res.params).not_to be_empty
        expect(res.params["transaction_history_id"]).not_to be_blank
        expect(res.params["transaction_id"]).not_to be_blank
      end
    end

    describe "setup -> authorize -> void" do
      it "successfully passes" do
        exp_date = Date.today + 365

        payer, payment_method = gateway.setup(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :email => "john.doe@nowhere.net", :account_number => "4111111111111111", :description => "test credit card", :payment_method_type => "Visa", :country => "USA", :expiration_date => exp_date.strftime("%m%y"))
        expect(payer[:payer_id]).not_to be_blank
        expect(payment_method[:payment_method_id]).not_to be_blank

        res = gateway.authorize("350", payment_method[:payment_method_id], :payer_id => payer[:payer_id], :currency_code => "USD")
        expect(res).to be_success
        expect(res.authorization).not_to be_blank
        expect(res.params).not_to be_empty
        expect(res.params["transaction_history_id"]).not_to be_blank
        expect(res.params["transaction_id"]).not_to be_blank

        auth = res.authorization
        extra_auth = {
          :transaction_history_id => res.params["transaction_history_id"],
          :original_transaction_id => res.params["transaction_id"]
        }

        res = gateway.void(auth, extra_auth)
        expect(res).to be_success
        expect(res.params).not_to be_empty
        expect(res.params["transaction_history_id"]).not_to be_blank
        expect(res.params["transaction_id"]).not_to be_blank
      end
    end

    describe "setup -> purchase" do
      it "successfully passes" do
        exp_date = Date.today + 365

        payer, payment_method = gateway.setup(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :email => "john.doe@nowhere.net", :account_number => "4111111111111111", :description => "test credit card", :payment_method_type => "Visa", :country => "USA", :expiration_date => exp_date.strftime("%m%y"))
        expect(payer[:payer_id]).not_to be_blank
        expect(payment_method[:payment_method_id]).not_to be_blank

        res = gateway.purchase("300", payment_method[:payment_method_id], :payer_id => payer[:payer_id], :currency_code => "USD")
        expect(res).to be_success
        expect(res.params).not_to be_empty
        expect(res.params["transaction_history_id"]).not_to be_blank
        expect(res.params["transaction_id"]).not_to be_blank
      end
    end

    describe "setup -> create_merchant_profile" do
      it "successfully passes" do
        payer = gateway.setup_payer(:external_id_1 => "1", :external_id_2 => "2", :name => "John Doe", :email => "john.doe@nowhere.net")

        profile_name = "Test Profile (#{Time.now})"
        res = gateway.create_merchant_profile(profile_name, :payment_processor => "LegacyProPay", :processor_data => {"certStr" => "75f8b88ad3c4edda87c529f4aa13a9", "termId" => "a13a9", "accountNum" => "31783139"})
        expect(res).not_to be_blank
      end
    end
  end

  describe "billing_address" do
    let(:gateway_options) do
      { :authentication_token => "4c9f4d70-a741-46c6-b1ed-e36432fea8e9",
        :biller_account_id => "8289197407827230",
        :billing_address => {
          :address_1 => "Nowhere 0",
          :address_2 => "Cellar",
          :city => "Gotham",
          :state => "NY",
          :phone => "+1-555-BATMAN",
          :zip => "54321"
        },
        :test => true }
    end

    subject { gateway.billing_address }

    it { should eq(:address_1 => "Nowhere 0", :address_2 => "Cellar", :city => "Gotham", :country => "USA", :state => "NY", :telephone_number => "+1-555-BATMAN", :zip_code => "54321") }
  end
end
