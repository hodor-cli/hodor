module Hodor::Oozie
  describe Action do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Action.instance_methods }

      # Public fields
      it { should include  :id }
      it { should include  :json }
      it { should include  :status }
      it { should include  :parent_id }
      it { should include  :error_message }
      it { should include  :data }
      it { should include  :transition }
      it { should include  :external_status }
      it { should include  :cred }
      it { should include  :type }
      it { should include  :end_time }
      it { should include  :external_id }
      it { should include  :start_time }
      it { should include  :external_child_ids }
      it { should include  :name }
      it { should include  :error_code }
      it { should include  :tracker_url }
      it { should include  :retries }
      it { should include  :to_string }
      it { should include  :console_url }

      # Public methods
      it { should include  :children }
    end

    context "Request action by job id" do
      include_context "hodor api" do
        let(:playback) { :sample_action }
      end

      let(:request_details) {
        /v1\/job\/0025060-151002103648730-oozie-oozi-W@run_worker/
      }

      let(:request_children) {
        /v1\/job\/0025062-151002103648730-oozie-oozi-W/
      }

      before(:each) do
        expect(session).to receive(:rest_call).with(request_details).once.and_mimic_original(memo)
        expect(session).to receive(:rest_call).with(request_children).once.and_mimic_original(memo)
        @action = oozie.job_by_id "0025060-151002103648730-oozie-oozi-W@run_worker"
        @children = @action.children
      end

      it "should have the correct type" do
        expect(@action.class).to eql(Hodor::Oozie::Action)
      end

      it "should have correct count" do
        expect(@action.type).to match(/sub-workflow/)
      end

      it "should have 1 child" do
        expect(@children.size).to eql(1)
      end

      it "should have example_business_W as only child" do
        expect(@children[0].app_name).to match(/example_business_W/)
      end
    end
  end
end
