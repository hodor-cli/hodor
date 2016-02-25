module Hodor::Oozie
  describe Coordinator do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Coordinator.instance_methods }

      # Public fields
      it { should include :status }
      it { should include :id }
      it { should include :json }
      it { should include :name }
      it { should include :path }
      it { should include :timezone }
      it { should include :frequency }
      it { should include :conf }
      it { should include :end_time }
      it { should include :execution_policy }
      it { should include :start_time }
      it { should include :time_unit }
      it { should include :concurrency }
      it { should include :last_action }
      it { should include :acl }
      it { should include :mat_throttling }
      it { should include :timeout }
      it { should include :next_materialized_time }
      it { should include :parent_id }
      it { should include :external_id }
      it { should include :group }
      it { should include :user }
      it { should include :console_url }
      it { should include :actions }
      it { should include :acl }
      it { should include :materializations }

      # Public methods
      it { should include :children }
    end

    context "Request coordinator by job id" do
      include_context "hodor api" do
        let(:playback) { :sample_coordinator }
      end

      let(:request_details) {
        /v1\/job\/0023753-151002103648730-oozie-oozi-C/
      }

      before(:each) do
        expect(session).to receive(:rest_call).with(request_details).once.and_mimic_original(memo)
        @coord = oozie.job_by_id "0023753-151002103648730-oozie-oozi-C"
        @children = @coord.children
      end

      it "should have the correct type" do
        expect(@coord.class).to eql(Hodor::Oozie::Coordinator)
      end

      it "should have 6 children" do
        expect(@children.size).to eql(6)
      end

      it "should show success status for child 2" do
        expect(@children[2].status).to eql("SUCCEEDED")
      end
    end
  end
end
