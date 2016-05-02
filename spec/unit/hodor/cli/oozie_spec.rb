require_thor 'oozie'

module Hodor::Cli
  describe Oozie do

    describe 'Required Public Interface' do
      subject { Oozie.instance_methods }

      # Public methods
      it { should include :run_job }
      it { should include :display_job }
      it { should include :change_job }
      it { should include :pwj }
      it { should include :kill_job }
    end

    context "Display jobs on test cluster" do
      include_context "hodor cli" do
        let(:verbose) { false }
        let(:run) { "oozie:display_job /" }
        let(:sample_coord) {
          JSON.parse(%Q[{
              "total": 0,
              "pauseTime": null,
              "coordJobName": "test_coord",
              "coordJobPath": "hdfs://test.test.com:8020/workflow.xml",
              "timeZone": "America/New_York",
              "frequency": "1",
              "conf": null,
              "endTime": "Mon, 18 Apr 2016 10:25:00 GMT",
              "executionPolicy": "FIFO",
              "startTime": "Mon, 18 Apr 2016 10:15:00 GMT",
              "timeUnit": "DAY",
              "concurrency": 1,
              "coordJobId": "0011111-222222222222222-oozie-oozi-C",
              "lastAction": "Tue, 19 Apr 2016 10:15:00 GMT",
              "status": "KILLED",
              "acl": null,
              "mat_throttling": 0,
              "timeOut": 1441,
              "nextMaterializedTime": "Tue, 19 Apr 2016 10:15:00 GMT",
              "bundleId": null,
              "toString": "Coordinator application id[0011111-222222222222222-oozie-oozi-C] status[KILLED]",
              "coordExternalId": null,
              "group": null,
              "user": "taskmaster",
              "consoleUrl": null,
              "actions": []
            }])
        }
      end

      before do
        use_settings ssh_user: 'the_job_user'
        allow(Hodor::Oozie).to receive(:job_by_path).once.with('/', true, []) { |arg| 
          Hodor::Oozie::Coordinator.new(sample_coord)
        }
      end

      it "should print value" do
        assert { result.is_ok? }
        assert { result.stdout =~ /Rspec: Coordinator Properties/ && result.stdout =~ /Rspec @ \d\d-\d\d/ }
      end
    end

  end
end
