module Hodor::Oozie
  describe Job do
    describe "Required Public Interface" do
      subject { Hodor::Oozie::Job.instance_methods }

      # Public fields
      it { should include :id }

      # Public methods
      it { should include :children }
      it { should include :display_properties }
      it { should include :display_children }
    end
  end
end
