require 'hodor/configuration'
require 'hodor/config/yml_config_set'
require 'hodor/config/edn_config_set'
require 'Hodor/config/config_set'
require 'active_support/core_ext/hash'

module Hodor

  describe Configuration do

    describe "Required Class Methods" do

      subject(:config) { Hodor::Configuration.methods  }

      # Public methods
      it { should include :config_definitions_sets }
    end

    context "Test reading config definition sets " do
      subject { Configuration.config_definitions_sets }
      it "returns hash containing order collection of load sets for each configuration" do
        results = subject.hash.deep_symbolize_keys
        expect(results.length).to eq 3
        expect(results.keys).to eq([:secrets, :clusters, :egress])
        expect(results[:clusters]).to be_kind_of(Array)
        expect(results[:clusters].length).to eq 3
      end
    end

    describe "Required Public Interface" do

      # .instance instead of .new necessitated by singleton:
      subject(:config) { Hodor::Configuration.instance_methods }

      # Public fields
      it { should include :logger }

      # Public methods
      it { should include :env }
      it { should include :config_defs }
      it { should include :load }
      it { should include :config_sets }
      it { should include :process }
      it { should include :config_hash }
      it { should include :config_name }
    end

    describe "Instance methods" do

      subject(:config) { Hodor::Configuration.new(config_name) }

      context 'secrets config' do
        let(:config_name) { 'secrets' }

        it "returns config defs " do
          expect(config.config_defs.length).to eq 2
          expect(config.config_defs.map(&:keys).flatten).to eq([:yml, :edn])
        end

        it "returns a set of configs of the correct class " do
          expect(config.config_sets.length).to eq 2
          expect(config.config_sets.map(&:class).map(&:name)).to eq(['Hodor::Config::YmlConfigSet',
                                                                     'Hodor::Config::EdnConfigSet'])
        end

        it "merges config sets to get a single hash" do
          expect(config.config_hash).to eq({ test: { all_props:{ test_prop: { test_key: "edn test value",
                                                                                 test_key1: "test value1"}}}})
        end
      end

      context 'clusters config' do
        let(:config_name) { 'clusters' }
        it "returns config defs " do
          expect(config.config_defs.length).to eq 3
          expect(config.config_defs.map(&:keys).flatten).to eq([:yml, :edn, :edn])
        end
      end

    end

  end
end
