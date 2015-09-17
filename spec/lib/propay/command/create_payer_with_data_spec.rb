require "spec_helper"

describe ProPay::Command::CreatePayerWithData do
  let(:command) { described_class.new(:authentication_token => "123token", :biller_account_id => "768", :name => "John Doe", :test => true) }

  describe "request" do
    subject { command.request }

    it { respond_to :to_xml }

    it "has required XML tags" do
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreatePayerWithData/con:identification/typ:AuthenticationToken[.='123token']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreatePayerWithData/con:identification/typ:BillerAccountId[.='768']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:CreatePayerWithData/con:data/typ:Name[.='John Doe']")).to be
    end
  end

  describe "response" do
    let(:response) { command }

    subject { command }

    before do
      body = <<XML
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>
    <CreatePayerWithDataResponse xmlns="http://propay.com/SPS/contracts">
      <CreatePayerWithDataResult xmlns:a="http://propay.com/SPS/types" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <a:ExternalAccountID>3184352714344653</a:ExternalAccountID>
        <a:RequestResult>
          <a:ResultCode>00</a:ResultCode>
          <a:ResultMessage/>
          <a:ResultValue>SUCCESS</a:ResultValue>
        </a:RequestResult>
      </CreatePayerWithDataResult>
    </CreatePayerWithDataResponse>
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

    describe "payer_id" do
      subject { response.payer_id }

      it { should eq "3184352714344653" }
    end
  end
end
