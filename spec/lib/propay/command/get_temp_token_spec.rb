require "spec_helper"

describe ProPay::Command::GetTempToken do
  let(:command) { described_class.new(:authentication_token => "123token", :biller_account_id => "768", :duration_seconds => 700, :payer_id => "999", :test => true) }

  describe "request" do
    subject { command.request }

    it { respond_to :to_xml }

    it "has required XML tags" do
      # TODO: see the comment in GetTempToken class
      # expect(subject.doc.at("//soapenv:Envelope/soapenv:Body/con:GetTempToken/con:tempTokenRequest/con:identification/typ:AuthenticationToken[.='123token']")).to be
      # expect(subject.doc.at("//soapenv:Envelope/soapenv:Body/con:GetTempToken/con:tempTokenRequest/con:identification/typ:BillerAccountId[.='768']")).to be
      expect(subject.doc.at("//soapenv:Envelope/soapenv:Body/con:GetTempToken/con:tempTokenRequest/typ:PayerInfo/typ:Id[.='999']")).to be
      expect(subject.doc.at("//soapenv:Envelope/soapenv:Body/con:GetTempToken/con:tempTokenRequest/typ:TokenProperties/typ:DurationSeconds[.='700']")).to be
    end
  end

  describe "response" do
    let(:response) { command }

    subject { command }

    before do
      body = <<XML
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <GetTempTokenResponse xmlns="http://propay.com/SPS/contracts">
      <GetTempTokenResult xmlns:a="http://propay.com/SPS/types" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:CredentialId>8797863</a:CredentialId>
        <a:PayerId>1029934042779067</a:PayerId>
        <a:RequestResult>
          <a:ResultCode>00</a:ResultCode>
          <a:ResultMessage/>
          <a:ResultValue>SUCCESS</a:ResultValue>
        </a:RequestResult>
        <a:TempToken>0dbdd4b9-f388-4f8d-9e36-dac9e76708108c60fb27-fab2-4114-9f70-2248f7ab4b05</a:TempToken>
      </GetTempTokenResult>
    </GetTempTokenResponse>
  </s:Body>
</s:Envelope>
XML
      command.instance_variable_set(:@response, Nokogiri::XML.parse(body))
    end

    it { should be_success }

    describe "message" do
      subject { response.message }

      it { should be_empty }
    end

    describe "code" do
      subject { response.code }

      it { should be_zero }
    end

    describe "value" do
      subject { response.value }

      it { should eq "SUCCESS" }
    end

    describe "fields" do
      subject { response.fields(:address_1 => "Nowhere str.0", :unidentified => "thing", :payment_process_type => "CreditCard", :process_method => "AuthOnly", :payment_method_storage_option => "OnSuccess", :payment_type_id => "JCB", :card_number => "4222222222222222", :exp_month => 11, :exp_year => 25, :currency_code => "USD", :amount => "3.50", :return_url => "http://localhost:3000/", :settings_cipher => "xxx") }

      it { should be_a Hash }

      it { should include "AuthToken" }
      it { should include "PayerId" }
      it { should include "CID" }
      it { should include "Address1" }
      it { should_not include "Unidentified" }
    end
  end
end
