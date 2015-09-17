require "spec_helper"

describe ProPay::Command::CreateMerchantProfile do
  let(:command) { described_class.new(:authentication_token => "123token", :biller_account_id => "768", :payment_processor => "LegacyProPay", :profile_name => profile_name, :test => true) }
  let!(:profile_name) { "Test Profile (#{Time.now})" }

  describe "request" do
    subject { command.request }

    it { respond_to :to_xml }

    it "has required XML tags" do
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreateMerchantProfile/con:identification/typ:AuthenticationToken[.='123token']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreateMerchantProfile/con:identification/typ:BillerAccountId[.='768']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreateMerchantProfile/con:merchantProfile/prop:PaymentProcessor[.='LegacyProPay']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreateMerchantProfile/con:merchantProfile/prop:ProfileName[.='#{profile_name}']")).to be
    end
  end

  describe "response" do
    let(:response) { command }

    subject { command }

    before do
      body = <<XML
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <CreateMerchantProfileResponse xmlns="http://propay.com/SPS/contracts">
      <CreateMerchantProfileResult xmlns:a="http://schemas.datacontract.org/2004/07/Propay.Contracts.SPS.External" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:ProfileId>368997</a:ProfileId>
        <a:RequestResult xmlns:b="http://propay.com/SPS/types">
          <b:ResultCode>00</b:ResultCode>
          <b:ResultMessage/>
          <b:ResultValue>SUCCESS</b:ResultValue>
        </a:RequestResult>
      </CreateMerchantProfileResult>
    </CreateMerchantProfileResponse>
  </s:Body>
</s:Envelope>
XML
      command.instance_variable_set(:@response, Nokogiri::XML.parse(body))
    end

    it { should be_success }
  end
end
