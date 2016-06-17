require  'hodor/config/local_loader'
module Hodor::Config
  describe S3Loader do

    describe "Required methods" do
      subject { LocalLoader.instance_methods }
      it { should include :properties }
      it { should include :config_file_name }
      it { should include :format_suffix }
      it { should include :folder }
      it { should include :file_path }
      it { should include :absolute_file_path }
      it { should include :exists? }
      it { should include :load_text }
    end

    describe "Key instance methods" do
      subject { LocalLoader.new(props, format_suffix)}
      let(:good_properties) { { folder: 'config', config_file_name: 'clusters'} }
      let(:invalid_location) { { folder: 'config/.private', config_file_name: 'bad_name' } }
      let(:empty_properties) {  {}  }
      let(:format_suffix) { 'yml' }
      context "valid props"  do
        let(:props) { good_properties }
        it { should be_kind_of(LocalLoader) }
        it "correctly constructs file_path" do
          expect(subject.file_path).to eq "config/clusters.yml"
        end
        it "checks if file exists" do
          expect(subject.exists?).to be_truthy
        end
        it "loads file" do
          results = subject.load_text
          expect(results).to be_kind_of(String)
          expect(results.length).to be > 1
        end
      end

      context "no filename"  do
        let(:props) { empty_properties }
        let(:error_message) { "Missing load configs. Input: properties={} and filename= ." }
        it "raises a not error" do
          expect {subject}.to raise_error(RuntimeError, error_message)
        end
      end

      context "file does not exist" do
        let(:props) { invalid_location }
        let(:path_def) { { yml: { local: { folder: 'config/.private', config_file_name: 'bad_name' }}} }
        it "warns there is no file and returns nil" do
          expect(subject.logger).to receive(:warn).with(/No file at/)
          expect(subject.load_text).to be_nil
        end
      end
    end
  end
end
