require  'hodor/config/yml_config_set'

module Hodor::Config

  describe YmlConfigSet do

    describe "Required methods" do
      subject { ConfigSet.instance_methods }
      it { should include :loader }
      it { should include :properties }
    end

  end
end
