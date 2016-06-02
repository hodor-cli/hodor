require  'hodor/config/config_set'

module Hodor::Config

  describe ConfigSet do

    describe "Required Class Method" do
      subject { ConfigSet.methods }
      # Class method
      it { should include :new_config_set }
    end

    describe "new_config_set" do
      subject {ConfigSet.new_config_set("test", path_def)}

      context "edn format type" do
        let(:path_def) { { edn: { tst: 'tst' }} }
        it { should be_kind_of(EdnConfigSet) }
      end

      context "yml format type" do
        let(:path_def) { { yml: { tst: 'tst' }} }
        it { should be_kind_of(YmlConfigSet) }
      end

      context "bad format type" do
        let(:path_def) { { bad_format: { tst: 'tst' }} }
        it "raises a not implemented error" do
          expect {subject}.to raise_error(NotImplementedError, "Bad Format is not a supported format")
        end
      end
    end

    describe "local loading with new config set construction" do
      subject {ConfigSet.new_config_set(name, path_def)}

      context "edn format reading local file" do
        let(:name) { "TestConfiguration"}
        let(:path_def) { { edn: { local: { folder: 'config/.private', config_file_name: 'secrets' }}} }
      end

    end


    describe "Required base class instance methods" do
      subject { ConfigSet.instance_methods }
      it { should include :loader }
      it { should include :properties }
      it { should include :defaults }
      it { should include :name }
      it { should include :format_extension }
    end

    describe "Base class instance methods" do
      subject { ConfigSet.new("test", properties, {}).loader }
      context "local loader type"  do
        let(:properties) { {local: { bucket: 'tst_bucket', folder: 'tst_folder', config_file_name: 'config' }} }
        it { should be_kind_of(LocalLoader) }
      end

      context "s3 loader type"  do
        let(:properties) { {s3: { bucket: 'tst_bucket', folder: 'tst_folder' , config_file_name: 'config'}} }
        it { should be_kind_of(S3Loader) }
      end

      context "bad loader type"  do
        let(:properties) { {bad_loader: { bucket: 'tst_bucket', folder: 'tst_folder', config_file_name: 'config' }} }
        it "raises a not error" do
          expect {subject}.to raise_error(RuntimeError, "Invalid file loader definition must be one of s3, local")
        end
      end
    end
  end
end
