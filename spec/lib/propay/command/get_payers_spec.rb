require "spec_helper"

describe ProPay::Command::GetPayers do
  let(:command) { described_class.new(:authentication_token => "123token", :biller_account_id => "768", :email => "nobody@nowhere.net", :test => true) }

  describe "request" do
    subject { command.request }

    it { respond_to :to_xml }

    it "has required XML tags" do
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:GetPayers/con:billerId/typ:AuthenticationToken[.='123token']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:GetPayers/con:billerId/typ:BillerAccountId[.='768']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:GetPayers/con:criteria/typ:EmailAddress[.='nobody@nowhere.net']")).to be
    end
  end

  describe "response" do
    let(:response) { command }

    subject { command }

    before do
      body = <<XML
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <GetPayersResponse xmlns="http://propay.com/SPS/contracts">
      <GetPayersResult xmlns:a="http://propay.com/SPS/types" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:Payers>
          <a:PayerInfo>
            <a:ExternalId1/>
            <a:ExternalId2/>
            <a:Name>test20131025b?</a:Name>
            <a:payerAccountId>7415305428076416</a:payerAccountId>
          </a:PayerInfo>
        </a:Payers>
        <a:RequestResult>
          <a:ResultCode>00</a:ResultCode>
          <a:ResultMessage/>
          <a:ResultValue>SUCCESS</a:ResultValue>
        </a:RequestResult>
      </GetPayersResult>
    </GetPayersResponse>
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

    describe "payers" do
      subject { response.payers }

      it { should eq [{:name => "test20131025b?", :payer_id => "7415305428076416"}] }
    end
  end
end
