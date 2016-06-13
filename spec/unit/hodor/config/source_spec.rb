require 'hodor/config/source'
require 'active_support/core_ext/hash'

module Hodor::Config

  describe Source do

    describe "Required Class Method" do
      subject { Source.methods }
      # Class method
      it { should include :new_source }
    end

    describe "new_source" do
      subject {Source.new_source("test", path_def)}

      context "edn format type" do
        let(:path_def) { { edn: { tst: 'tst' }} }
        it { should be_kind_of(EdnSource) }
      end

      context "yml format type" do
        let(:path_def) { { yml: { tst: 'tst' }} }
        it { should be_kind_of(YmlSource) }
      end

      context "bad format type" do
        let(:path_def) { { bad_format: { tst: 'tst' }} }
        it "raises a not implemented error" do
          expect {subject}.to raise_error(NotImplementedError, "Bad Format is not a supported format")
        end
      end
    end

    describe "local loading with new config set construction" do
      subject {Source.new_source(name, path_def)}
      let(:expected_hash) { { test: { all_props: { test_prop: { test_key: "test value"}}}} }
      context "edn format reading local secrets file" do
        let(:name) { "TestConfiguration"}
        let(:path_def) { { edn: { local: { folder: 'config/.private', config_file_name: 'secrets' }}} }
        it "returns hash containing secrets" do
          results = subject.config_hash
          expect(results).to be_kind_of(Hash)
          expect(results.deep_symbolize_keys).to eq(expected_hash)
        end
      end

      context "yml format reading local secrets file" do
        let(:name) { "TestConfiguration"}
        let(:path_def) { { yml: { local: { folder: 'config/.private', config_file_name: 'secrets' }}} }
        it "returns hash containing secrets" do
          results = subject.config_hash
          expect(results).to be_kind_of(Hash)
          expect(results.deep_symbolize_keys).to eq(expected_hash)
        end
      end

      context "file does not exist" do
        let(:name) { "TestConfiguration"}
        let(:path_def) { { yml: { local: { folder: 'config/.private', config_file_name: 'bad_name' }}} }
        it "raises an no file at error" do
          expect {subject.config_hash}.to raise_error(RuntimeError, /No file at/)
        end
      end

      context "yml format reading local file" do
        let(:name) { "TestConfiguration"}
        let(:path_def) { { yml: { local: { folder: 'config', config_file_name: 'clusters' }}} }
        it "returns hash containing secrets" do
          results = subject.config_hash
          expect(results).to be_kind_of(Hash)
          expect(results.keys).to eq( [:rspec])
        end
      end
    end

    describe "Required base class instance methods" do
      subject { Source.instance_methods }
      it { should include :loader }
      it { should include :properties }
      it { should include :defaults }
      it { should include :name }
      it { should include :format_extension }
    end

    describe "Base class instance methods" do
      subject { Source.new("test", properties).loader }
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
