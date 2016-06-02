require  'hodor/config/loader'
module Hodor::Config
  describe Loader do

    describe "Required methods" do
      subject { Loader.instance_methods }
      it { should include :properties }
      it { should include :config_file_name }
      it { should include :format_type }
    end
  end
end
