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
      it { should include :no_op}
      it { should include :yml_load }
      it { should include :root }
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

      it 'loads settings'  do
        tmp =  env.load_settings
        expect(tmp).to eq base_cluster_configs
      end
    end
    context 'transforming yaml' do
      subject(:environment) { Hodor::Environment.instance }
      let(:part_to_process) { "${name}:${^name}:${^^name}:${^^^name}" }
      let(:processed_yml) { 'gg1:g1:c1:p1' }
      let(:yml_read) { {rspec: { rspec: { parent: { name: "p1",
                                                    child: { name: "c1",
                                                                grandchild: { name: "g1",
                                                                                 ggrandchild: { name: "gg1" }}}},
                                          family_tree: part_to_process }}}}
      let(:target_env) { environment.hadoop_env.to_sym }
      let(:target_yml) { [yml_read[target_env]] }

      it 'process yml variables' do
        expect(environment.yml_expand(yml_read, target_yml)[:rspec][:rspec][:family_tree]).to eq processed_yml
      end
    end
  end
end
