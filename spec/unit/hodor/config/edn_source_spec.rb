require 'hodor/config/edn_source'

module Hodor::Config

  describe EdnSource do

    describe "Required methods" do
      subject { EdnSource.instance_methods }
      it { should include :loader }
      it { should include :properties }
      it { should include :defaults }
      it { should include :name }
      it { should include :format_extension }
    end

  end
end
