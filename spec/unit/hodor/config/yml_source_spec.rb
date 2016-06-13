require 'hodor/config/yml_source'

module Hodor::Config

  describe YmlSource do

    describe "Required methods" do
      subject { Source.instance_methods }
      it { should include :loader }
      it { should include :properties }
      it { should include :defaults }
      it { should include :name }
      it { should include :format_extension }
    end

  end
end
