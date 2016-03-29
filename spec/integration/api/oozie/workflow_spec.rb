module Hodor::Oozie
  describe Workflow do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Workflow.instance_methods }

      # Public fields
      it { should include :id }
      it { should include :json }
      it { should include :app_path }
      it { should include :acl }
      it { should include :status }
      it { should include :created_at }
      it { should include :conf }
      it { should include :last_mod_time }
      it { should include :run }
      it { should include :end_time }
      it { should include :external_id }
      it { should include :app_name }
      it { should include :start_time }
      it { should include :materialization_id }
      it { should include :parent_id }
      it { should include :materialization }
      it { should include :to_string }
      it { should include :group }
      it { should include :console_url }
      it { should include :user }

      # Public methods
      it { should include :children }
    end

    context "List all running coordinators" do
      include_context "hodor api" do
        let(:playback) { :sample_workflow }
      end

      let(:request) {
        /v1\/job\/0025062-151002103648730-oozie-oozi-W/
      }

      before(:each) do
        expect(session).to receive(:rest_call).with(request).once.and_mimic_original(memo)
        @workflow = oozie.job_by_id "0025062-151002103648730-oozie-oozi-W"
        @children = @workflow.children
      end

      it "should have the correct type" do
        expect(@workflow.class).to eql(Hodor::Oozie::Workflow)
      end


      it "should have correct count" do
        expect(@workflow.app_name).to match(/example_business_W/)
      end

      it "should have 3 children" do
        expect(@children.size).to eql(3)
      end

      it "should have 3 children" do
        expect(@children[1].name).to match(/data_workflow/)
      end
    end
  end
end
