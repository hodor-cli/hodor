require  'hodor/config/loader'
module Hodor::Config
  describe Loader do

    describe "Required methods" do
      subject { Loader.instance_methods }
      it { should include :properties }
      it { should include :config_file_name }
      it { should include :format_suffix }
    end

    describe "Key instance methods" do
      subject { Loader.new(props, format_suffix)}
      let(:good_properties) { { config_file_name: 'test_configs' } }
      let(:empty_properties) {  {}  }

      let(:format_suffix) { 'edn'}
      context "valid props"  do
        let(:props) { good_properties }
        it { should be_kind_of(Loader) }
        it "correctly constructs object key" do
          expect(subject.properties).to eq good_properties

        end
      end

      context "empty props"  do
        let(:props) { empty_properties }
        let(:error_message) { "Missing load configs. Input: properties={} and filename= ." }
        it "raises a not error" do
          expect {subject}.to raise_error(RuntimeError, error_message)
        end
      end
    end
  end
end
