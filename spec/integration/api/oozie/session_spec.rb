module Hodor::Oozie
  describe Session do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Session.instance_methods }

      # Public methods
      it { should include :pwj }
      it { should include :hadoop_env }
      it { should include :make_current }
      it { should include :current_id }
      it { should include :current_id }
      it { should include :get_job_state }
      it { should include :search_jobs }
      it { should include :len }
      it { should include :offset }
    end
  end
end

