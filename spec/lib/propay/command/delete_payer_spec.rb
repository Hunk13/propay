require "spec_helper"

describe ProPay::Command::DeletePayer do
  let(:command) { described_class.new(:authentication_token => "123token", :biller_account_id => "768", :payer_id => "3", :test => true) }

  describe "request" do
    subject { command.request }

    it { respond_to :to_xml }

    it "has required XML tags" do
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:DeletePayer/con:identification/typ:AuthenticationToken[.='123token']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:DeletePayer/con:identification/typ:BillerAccountId[.='768']")).to be
      expect(subject.doc.at("/soapenv:Envelope/soapenv:Body/con:DeletePayer/con:payerAccountId[.='3']")).to be
    end
  end
end
