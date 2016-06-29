require 'hodor/api/hdfs'

module Hodor

  describe Hdfs do
    let(:env) { Hodor::Environment.instance }
    describe "Required Public Interface" do

      # .instance instead of .new necessitated by singleton:
      subject(:hdfs_methods) { Hodor::Hdfs.instance_methods }

      # Public methods
      it { should include :pwd }
      it { should include :path_on_hdfs }

    end

    context "test local to hdfs path operations" do
      subject(:hdfs) { Hodor::Hdfs.instance }
      before(:each) do
        use_settings hdfs_root: "/", hdfs_user: "hdfs"
        use_pwd "company/workers/noop", false
      end

      context "ensure pwd maps correctly between file systems" do
        it "should correctly map test repo path to HDFS path" do
          expect(env).to receive(:secrets)
          expect(hdfs.pwd).to match(/\/company\/workers\/noop/)
        end
      end

      context "test putting file to HDFS" do
        it "should successfully construct ssh commandline to put file to HDFS" do
          expect(env).to receive(:secrets)
          expect(File).to receive(:exists?).with(/workflow.xml/).exactly(2).times { true }
          expect(env).to receive(:run_local).with(/cat workflow.xml.*=hdfs\s.*-put - \/company\/workers\/noop\/workflow.xml/, anything)
          hdfs.put_file("workflow.xml")
        end
      end

      context "test putting directory to HDFS" do
        it "should successfully construct ssh commandline to put directory to HDFS" do
          expect(env).to receive(:secrets)
          expect(File).to receive(:exists?).with(/workflow.xml/).exactly(2).times { true }
          expect(env).to receive(:run_local).with(/cat workflow.xml.*=hdfs\s.*-put - \/company\/workers\/noop\/workflow.xml/, anything)
          hdfs.put_file("workflow.xml")
        end
      end
    end
  end
end
