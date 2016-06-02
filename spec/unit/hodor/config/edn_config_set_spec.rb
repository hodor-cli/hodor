require  'hodor/config/edn_config_set'

module Hodor::Config

  describe EdnConfigSet do

    describe "Required methods" do
      subject { EdnConfigSet.instance_methods }
      it { should include :loader }
      it { should include :properties }
      it { should include :defaults }
      it { should include :name }
      it { should include :format_extension }
    end

  end
end
