require "spec_helper"

describe ProPay::Command::EditPayer do
  let(:command) { described_class.new(:authentication_token => "123token", :biller_account_id => "768", :payer_id => "3", :name => "John Doe", :test => true) }

  describe "request" do
    subject { command.request }

    it { respond_to :to_xml }

    it "has required XML tags" do
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:identification/typ:AuthenticationToken[.='123token']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:identification/typ:BillerAccountId[.='768']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:request/prop:PayerAccountId[.='3']")).to be
    end

    it "includes updated attributes" do
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:request/prop:UpdatedData/typ:Name[.='John Doe']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:request/prop:UpdatedData/typ:EmailAddress")).not_to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:request/prop:UpdatedData/typ:ExternalId1")).not_to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:EditPayerV2/con:request/prop:UpdatedData/typ:ExternalId2")).not_to be
    end
  end
end
