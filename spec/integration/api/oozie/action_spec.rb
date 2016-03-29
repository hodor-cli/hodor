module Hodor::Oozie
  describe Action do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Action }

      # Public fields
      it { should respond_to? :id }
      it { should respond_to? :json }
      it { should respond_to? :status }
      it { should respond_to? :parent_id }
      it { should respond_to? :error_message }
      it { should respond_to? :data }
      it { should respond_to? :transition }
      it { should respond_to? :external_status }
      it { should respond_to? :cred }
      it { should respond_to? :type }
      it { should respond_to? :end_time }
      it { should respond_to? :external_id }
      it { should respond_to? :start_time }
      it { should respond_to? :external_child_ids }
      it { should respond_to? :name }
      it { should respond_to? :error_code }
      it { should respond_to? :tracker_url }
      it { should respond_to? :retries }
      it { should respond_to? :to_string }
      it { should respond_to? :console_url }

      # Public methods
      it { should respond_to? :children }
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
