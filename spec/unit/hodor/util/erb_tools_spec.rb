require  'hodor/util/erb_tools'

module Hodor::Util

  describe ErbTools do

    describe "Required Public Interface" do
      subject(:erb_tool_methods) { Hodor::Util::ErbTools.instance_methods }

      # Public methods
      it { should include :erb_load }
      it { should include :erb_sub }
    end

    context 'loading yaml' do
      subject(:environment) { Hodor::Environment.instance }

      let(:input_txt) { ':foo: 1 \n :foo2: two' }
      let(:processed_yml) { ":foo: 1 \\n :foo2: two" }
      before do
        allow(File).to receive(:exists?).and_return(true)
        allow(File).to receive(:read).and_return(input_txt)

      end

      it 'reads input' do
        expect(environment.erb_load(input_txt)).to eq processed_yml
      end
    end
  end
end
