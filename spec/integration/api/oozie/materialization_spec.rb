module Hodor::Oozie
  describe Materialization do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Materialization.instance_methods }

      # Public fields
      it { should include :id }
      it { should include :json }
      it { should include :error_message }
      it { should include :last_modified_time }
      it { should include :created_at }
      it { should include :status }
      it { should include :push_missing_dependencies }
      it { should include :external_status }
      it { should include :type }
      it { should include :nominal_time }
      it { should include :external_id }
      it { should include :created_conf }
      it { should include :missing_dependencies }
      it { should include :run_conf }
      it { should include :action_number }
      it { should include :error_code }
      it { should include :tracker_uri }
      it { should include :to_string }
      it { should include :parent_id }
      it { should include :coord_job_id }
      it { should include :console_url }

      # Public methods
      it { should include :children }
    end

    context "Request materialization by job id" do
      include_context "hodor api" do
        let(:playback) { :sample_materialization }
      end

      let(:request_details) {
        /v1\/job\/0023753-151002103648730-oozie-oozi-C/
      }

      let(:request_children) {
        /v1\/job\/0025060-151002103648730-oozie-oozi-W/
      }

      before(:each) do
        expect(session).to receive(:rest_call).with(request_details).once.and_mimic_original(memo)
        expect(session).to receive(:rest_call).with(request_children).once.and_mimic_original(memo)
        @materialization = oozie.job_by_id "0023753-151002103648730-oozie-oozi-C@3"
        @children = @materialization.children
      end

      it "should have the correct type" do
        expect(@materialization.class).to eql(Hodor::Oozie::Materialization)
      end

      it "should have 1 child" do
        expect(@children.size).to eql(1)
      end

      it "should show success status for child 0" do
        expect(@children[0].status).to eql("SUCCEEDED")
      end
    end
  end
end
