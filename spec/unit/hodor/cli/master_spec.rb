require_thor 'master'

module Hodor::Cli
  describe Master do
    describe 'Required Public Interface' do
      subject { Master.instance_methods }

      # Public methods
      it { should include :print }
      it { should include :config }
      it { should include :exec }
      it { should include :ssh_config }
    end

    context "Print value for given key" do
      include_context "hodor cli" do
        let(:verbose) { false }
        let(:run) { "master:print ssh_user" }
      end

      before do
        use_settings ssh_user: 'the_job_user'
      end

      it "should print value" do
        assert { result.is_ok? }
        assert { result.stdout =~ /the_job_user/ }
      end
    end

    context "Execute pre-configured command" do
      include_context "hodor cli" do
        let(:verbose) { false }
        let(:run) { "master:exec :source_hive test.hql" }
      end

      before do
        use_settings commands: {
          source_hive: {
            line: 'beeline -n test -u test_url -f',
            ssh: false
          }
        }
        expect(env).to receive(:run_local)
          .with(/beeline -n test -u test_url -f test.hql/, ssh: false).once
      end

      it "should build expected command line from pre-configured command" do
        assert { result.is_ok? }
      end
    end
  end
end
