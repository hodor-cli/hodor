module Hodor::Oozie
  describe Bundle do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Bundle.instance_methods }

      # Public fields
      it { should include :status }

      # Public methods
      it { should include :children }
    end

    context "Request bundle by job id that does not exist" do
      include_context "hodor api" do
        let(:playback) { :sample_bundle }
      end

      let(:request_details) {
        /v1\/job\/0023753-151002103648730-oozie-oozi-B/
      }

      before(:each) do
        expect(session).to receive(:rest_call).with(request_details).once.and_mimic_original(memo)
      end

      it "should should throw exception when searching for a bundle that does not exist" do
        expect {
          oozie.job_by_id "0023753-151002103648730-oozie-oozi-B"
        }.to raise_error JSON::ParserError
      end
    end
  end
end
