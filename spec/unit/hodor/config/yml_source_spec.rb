require 'hodor/config/source'

module Hodor::Config

  describe YmlSource do

    describe "Required methods" do
      subject { YmlSource.instance_methods }
      it { should include :loader }
      it { should include :properties }
      it { should include :defaults }
      it { should include :name }
      it { should include :format_extension }
      it { should include :config_hash }
    end
  end
end
