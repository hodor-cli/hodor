module Hodor::Oozie
  describe Session do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Session }

      # Public methods
      it { should respond_to? :pwj }
      it { should respond_to? :hadoop_env }
      it { should respond_to? :make_current }
      it { should respond_to? :current_id }
      it { should respond_to? :current_id }
      it { should respond_to? :get_job_state }
      it { should respond_to? :search_jobs }
      it { should respond_to? :len }
      it { should respond_to? :offset }
    end
  end
end

