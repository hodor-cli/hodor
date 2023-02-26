require 'hodor/environment'

module Hodor

  describe Environment do

    describe "Required Public Interface" do

      # .instance instead of .new necessitated by singleton:
      subject(:hadoop_env) { Hodor::Environment.instance_methods }

      # Public fields
      it { should include :logger }

      # Public methods
      it { should include :erb_sub }
      it { should include :erb_load }
      it { should include :yml_expand}
      it { should include :yml_flatten}
      it { should include :yml_load }
      it { should include :root }
      it {should include :secrets}
    end
  end
end
