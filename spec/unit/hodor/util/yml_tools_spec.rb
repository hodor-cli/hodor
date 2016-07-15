require  'hodor/util/yml_tools'

module Hodor::Util

  describe YmlTools do

    describe "Required Public Interface" do
      subject(:yml_tool_methods) { Hodor::Util::YmlTools.instance_methods }

      # Public methods
      it { should include :yml_expand}
      it { should include :yml_flatten}
      it { should include :yml_load }
      it { should include :erb_load }
      it { should include :erb_sub }
    end

    context 'loading yaml' do
      subject(:environment) { Hodor::Environment.instance }

      let(:input_yml) { "foo: 1 \nfoo2: two" }
      let(:processed_yml) { {"foo"=>1, "foo2"=>"two"} }

      before do
        allow(environment).to receive(:erb_load).and_return(input_yml)
      end
      it 'reads yml' do
        expect(environment.yml_load(input_yml)).to eq processed_yml
      end
    end

    context 'expanding yaml' do
      subject(:environment) { Hodor::Environment.instance }
      let(:part_to_process) { "${name}:${^name}:${^^name}:${^^^name}" }
      let(:processed_yml) { 'gg1:g1:c1:p1' }
      let(:yml_read) { {rspec: { rspec: { parent: { name: "p1",
                                                    child: { name: "c1",
                                                                grandchild: { name: "g1",
                                                                                 ggrandchild: { name: "gg1" }}}},
                                          family_tree: part_to_process }}}}
      let(:target_env) { environment.hadoop_env.to_sym }
      let(:target_yml) { [yml_read[target_env]] }

      it 'process yml variables' do
        expect(environment.yml_expand(yml_read, target_yml)[:rspec][:rspec][:family_tree]).to eq processed_yml
      end
    end

    context 'flattening yaml' do
      subject(:environment) { Hodor::Environment.instance }
      let(:processed_yml_with_key) { ["l0.l1.l2 = tst", "l0.l1.l2a.l3 = tst"] }
      let(:processed_yml_blank_key) { ["l1.l2 = tst", "l1.l2a.l3 = tst"] }
      let(:input_hash) {  {"l1"=>{"l2"=>"tst", "l2a"=>{"l3"=>"tst"}}} }
      let(:in_key) { 'l0' }
      let(:target_yml) { [yml_read[target_env]] }

      it 'flattens correctly with a key' do
        expect(environment.yml_flatten(in_key, input_hash)).to eq processed_yml_with_key
      end

      it 'flattens correctly when blank key passed in' do
        expect(environment.yml_flatten('', input_hash)).to eq processed_yml_blank_key
      end
      it 'flattens correctly when nil key passed in' do
        expect(environment.yml_flatten(nil, input_hash)).to eq processed_yml_blank_key
      end
    end
  end
end
