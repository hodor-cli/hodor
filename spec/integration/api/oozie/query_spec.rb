module Hodor::Oozie
  describe Query do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Query.instance_methods }

      # Public fields
      it { should include :id }
      it { should include :request }
      it { should include :json }

      # Public methods
      it { should include :children }
    end

    context "List all running coordinators" do
      include_context "hodor api" do
        let(:playback) { :running_coordinators }
      end

      let(:parent_request) {
        /v2\/jobs\?jobtype=coord&filter=status%3DRUNNING/
      }

      before(:each) do
        expect(session).to receive(:rest_call).with(parent_request).once.and_mimic_original(memo)
        @query = Hodor::Oozie::Query.new status: [:running]
        @matches = @query.children
      end

      it "should have correct count" do
        expect(@matches.size).to eql(4)
      end

      it "should include worker_data_source\/business_C coordinator" do
        expect(@matches[1].name).to match(/driver_example_workflows_master_workflow.xml_C/)
      end

      it "should include hourly_master incremental coordinator" do
        expect(@matches[0].name).to match(/example_workflows\/hourly_master_hourly_incremental-C/)
      end
    end
  end
end
