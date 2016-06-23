require 'hodor/environment'

module Hodor

  describe Environment do

    describe "Required Public Interface" do

      # .instance instead of .new necessitated by singleton:
      subject(:hadoop_env) { Hodor::Environment.instance_methods }

      # Public fields
      it { should include :logger }

      # Public methods
      it { should include :erb_sub }
      it { should include :erb_load }
      it { should include :yml_expand}
      it { should include :yml_flatten}
      it { should include :yml_load }
      it { should include :root }
      it {should include :secrets}
    end

    describe 'Ensure usable test repo' do

      # .instance instead of .new necessitated by singleton:
      subject(:env) { Hodor::Environment.instance }
      it "should have correct root" do
        expect(subject.root).to match(/spec\/test_repo/), "Hadoop_refrepo must be included under test_repo for tests to work.\n Use command line: git clone --recursive  git@github.com:data-wranglers/hodor.git"
      end

      it "should have a jobs.yml file in the testbench directory" do
        expect(File).to exist("#{subject.root}/drivers/testbench/jobs.yml")
      end
    end

    context "Test basic environment methods" do
      let(:base_cluster_configs) { { hdfs_root: "/", hdfs_user: "hdfs", target: :rspec } }
      subject(:env) { Hodor::Environment.instance }

      before(:each) do
        use_settings hdfs_root: "/", hdfs_user: "hdfs"
        use_pwd "drivers/testbench"
      end

      it 'paths_from_root returns all paths from root to pwd' do
        expect(
          env.paths_from_root(Dir.pwd)
        ).to match_array(
          [/spec\/test_repo/,
           /spec\/test_repo\/drivers/,
           /spec\/test_repo\/drivers\/testbench/]
        )
      end

      it 'loads and caches secrets' do
        expect_any_instance_of(Hodor::ConfigSet).to receive(:config_hash).once { { a: 'ok' } }
        expect(env.secrets).to eq({ a: 'ok' })
        expect(env.secrets).to eq({ a: 'ok' })
      end

      it 'loads settings'  do
        tmp =  env.load_settings
        expect(tmp).to eq base_cluster_configs
      end
    end
  end
end
