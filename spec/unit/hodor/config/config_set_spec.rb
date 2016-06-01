require  'hodor/config/config_set'

module Hodor::Config

  describe ConfigSet do

    describe "Required Class Method" do
      subject(:config_set_class_methods) { Hodor::Config::ConfigSet.methods }

      # Class method
      it { should include :new_config_set }
    end

    describe "new_config_set" do
      subject(:subject) {Hodor::Config::ConfigSet.new_config_set(path_def)}

      context "edn format type" do
        let(:path_def) { {edn: 'tst' } }
        it { should be_kind_of(EdnConfigSet) }
      end

      context "yml format type" do
        let(:path_def) { {yml: 'tst' } }
        it { should be_kind_of(YmlConfigSet) }
      end

      context "bad format type" do
        let(:path_def) { {bad_format: 'tst' } }
        it "raises a not implemented error" do
          expect {subject}.to raise_error(NotImplementedError, "Bad Format is not a supported format")
        end
      end
    end

  end
end
