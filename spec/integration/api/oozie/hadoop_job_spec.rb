module Hodor::Oozie
  describe HadoopJob do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::HadoopJob.instance_methods }

      # Public fields
      it { should include :id }
      it { should include :parent_id }

      # Public methods
      it { should include :children }
    end

    context "Request action by job id" do
      include_context "hodor api" do
        let(:playback) { :sample_hadoop_job }
        let(:env) { Hodor::Environment.instance }
      end

      before(:each) do
        expect(session).not_to receive(:rest_call)
        expect(env).to receive(:secrets)
        @job = oozie.job_by_id "job_1443733596356_96843"
      end

      it "should have the correct type" do
        expect(@job.class).to eql(Hodor::Oozie::HadoopJob)
      end
    end
  end
end
