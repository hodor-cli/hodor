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
      it { should include :yml_load }
      it { should include :root }
    end

    describe "Ensure usable test repo" do

      # .instance instead of .new necessitated by singleton:
      subject(:env) { Hodor::Environment.instance }

      it "should have correct root" do
        expect(subject.root).to match(/spec\/test_repo/)
      end
    end

    context "Test basic environment methods" do

      subject(:env) { Hodor::Environment.instance }

      before(:each) do
        use_settings hdfs_root: "/", hdfs_user: "hdfs"
        use_pwd "drivers/testbench"
      end

      it "should fail if no jobs.yml file exists" do
        expect(
          env.paths_from_root(Dir.pwd)
        ).to match_array(
          [/spec\/test_repo/,
           /spec\/test_repo\/drivers/,
           /spec\/test_repo\/drivers\/testbench/]
        )
      end
    end
  end
end
