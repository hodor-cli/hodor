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
      it { should include :load_text }
    end

    describe "Key initialization methods" do
      subject { S3Loader.new(props, format_suffix)}
      let(:good_properties) { { bucket: 'test_bucket', folder: 'test_folder', config_file_name: 'test_configs'} }
      let(:empty_properties) {  {}  }
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
        let(:error_message) { "Missing load configs. Input: properties={} and filename= ." }
        it "raises a not error" do
          expect {subject}.to raise_error(RuntimeError, error_message)
        end
      end

      context "missing AWS config"  do
        let(:props) { good_properties }
        let(:error_message) { "AWS connection configuration missing from your environment: AWS_ACCESS_KEY_ID=AKIAIYXJFSOHTMEHUT7A AWS_SECRET_ACCESS_KEY= AWS_REGION=us-east-1" }

        it "raises a not error" do
         expect(ENV).to receive(:[]).with('AWS_ACCESS_KEY_ID').once.and_return(nil)
         expect(ENV).to receive(:[]).at_least(:twice).and_call_original
          #allow(ENV).to receive(:[]).with('AWS_SECRET_ACCESS_KEY').and_return(nil)
          expect {subject}.to raise_error(RuntimeError, error_message)
        end

      end
    end
  end
end
