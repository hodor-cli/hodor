require  'hodor/config/s3_loader'
module Hodor::Config
  describe S3Loader do

    describe "Required methods" do
      subject { S3Loader.instance_methods }
      it { should include :properties }
      it { should include :config_file_name }
      it { should include :format_suffix }
      it { should include :bucket }
      it { should include :s3 }
      it { should include :object_key }
      it { should include :folder }
      it { should include :load }
    end

    describe "Key instance methods" do
      subject { S3Loader.new(props, config_file_name, format_suffix)}
      let(:good_properties) { { bucket: 'test_bucket', folder: 'test_folder' } }
      let(:empty_properties) {  {}  }
      let(:config_file_name) { 'test_configs'}
      let(:format_suffix) { 'edn'}
      context "valid props"  do
        let(:props) { good_properties }
        it { should be_kind_of(S3Loader) }
        it "correctly constructs object key" do
          expect(subject.object_key).to eq "test_folder/test_configs.edn"
        end
      end

      context "empty props"  do
        let(:props) { empty_properties }
        let(:error_message) { "Missing S3 load configs: bucket= and folder= ." }
        it "raises a not error" do
          expect {subject}.to raise_error(RuntimeError, error_message)
        end
      end
    end
  end
end
