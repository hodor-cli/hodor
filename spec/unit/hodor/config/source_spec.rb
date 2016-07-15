require 'log4r'
require 'log4r/configurator'
require 'hodor/config/source'
require 'active_support/core_ext/hash'

module Hodor::Config

  describe Source do

    describe "local loading with new config set construction" do
      subject {EdnSource.new(name, path_def[:edn])}
      let(:expected_hash) { { test: { all_props: { test_prop: { test_key: "test value"}}}} }
      context "edn format reading local secrets file" do
        let(:name) { "TestConfiguration"}
        let(:path_def) { { edn: { local: { folder: 'config/.private', config_file_name: 'secrets' }}} }
        it "returns hash containing secrets" do
          secrets_reading_edn
          results = subject.config_hash
          expect(results).to be_kind_of(Hash)
          expect(results.deep_symbolize_keys).to eq(expected_hash)
        end
      end
    end

    describe "local loading YML with new config set construction" do
      subject {YmlSource.new('test configuration', path_def[:yml])}
      let(:expected_hash) { { test: { all_props: { test_prop: { test_key: "test value"}}}} }
      context "yml format reading local secrets file" do
        let(:path_def) { { yml: { local: { folder: 'config/.private', config_file_name: 'secrets' }}} }
        before do
        end
        it "returns hash containing secrets" do
          secrets_reading_yml
          results = subject.config_hash
          expect(results).to be_kind_of(Hash)
          expect(results.deep_symbolize_keys).to eq(expected_hash)
        end
      end

      context "file does not exist" do
        let(:path_def) { { yml: { local: { folder: 'config/.private', config_file_name: 'bad_name' }}} }
        it "returns an empty hash" do
          expect_any_instance_of(Hodor::Config::Loader).to receive(:logger) { instance_double("Logger", :warn => "") }
          expect(subject.config_hash).to eq({ })
        end
      end

      context "yml format reading local file" do
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

    private

    def secrets_reading_yml
      good_secrets_private
      expect(File).to receive(:exists?).with(/secrets.yml/).once { true }
      expect(File).to receive(:read).with(/secrets.yml/).once { good_secrets_private }
    end

    def secrets_reading_edn
      good_secrets_private_edn
      expect(File).to receive(:exists?).with(/secrets.edn/).once { true }
      expect(File).to receive(:read).with(/secrets.edn/).once { good_secrets_private_edn }
    end

    def good_secrets_private
      @good_secrets_private ||= File.read('./spec/fixtures/config/.private/secrets.yml')
    end

    def good_secrets_private_edn
      @good_secrets_private ||= File.read('./spec/fixtures/config/.private/secrets.edn')
    end
  end
end
