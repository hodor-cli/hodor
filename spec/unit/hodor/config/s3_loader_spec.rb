require  'hodor/config/s3_loader'
module Hodor::Config
  describe S3Loader do

    describe "Required methods" do
      subject { S3Loader.instance_methods }
      it { should include :properties }
      it { should include :config_file_name }
      it { should include :format_type }
      it { should include :bucket }
    end
  end
end
