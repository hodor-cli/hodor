require 'hodor/config_set'

module Hodor

  describe ConfigSet do

    describe "Required Class Methods" do

      subject(:config) { Hodor::ConfigSet.methods  }

      # Public methods
      it { should include :config_definitions_sets }
    end

    context "Test reading config definition sets " do
      subject { ConfigSet.config_definitions_sets }
      it "returns hash containing order collection of load sets for each configuration" do
        good_definition_set
        expect(File).to receive(:exists?).with(/load_sets.yml/).once { true }
        expect(File).to receive(:read).with(/load_sets.yml/).once { good_definition_set }
        results = subject.config_hash
        expect(results.length).to eq 3
        expect(results.keys).to eq([:secrets, :clusters, :egress])
        expect(results[:clusters]).to be_kind_of(Array)
        expect(results[:clusters].length).to eq 3
      end
    end

    describe 'class methods and constants' do
      it 'should return correct constants' do
        expect(Hodor::ConfigSet::LOAD_SETS_FILE_SPECIFICATION).to eq({ yml:
                                                                           { local:
                                                                                 { folder: "config",
                                                                                   config_file_name: "load_sets" }}})
      end
    end


    describe "Required Public Interface" do

      subject(:config) { Hodor::ConfigSet.instance_methods }

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

      subject(:config) { Hodor::ConfigSet.new(config_name) }

      context 'secrets config' do
        let(:config_name) { 'secrets' }

        it "returns config defs " do
          expect(config.config_defs.length).to eq 2
          expect(config.config_defs.map(&:keys).flatten).to eq([:yml, :edn])
        end

        it "returns a set of configs of the correct class " do
          expect(config.config_sets.length).to eq 2
          expect(config.config_sets.map(&:class).map(&:name)).to eq(['Hodor::Config::YmlSource',
                                                                     'Hodor::Config::EdnSource'])
        end

        it "merges config sets to get a single hash" do
          good_secrets_basic
          good_definition_set
          good_secrets_private
          expect(File).to receive(:exists?).with(/load_sets.yml/).at_most(:once) { true }
          expect(File).to receive(:read).with(/load_sets.yml/).at_most(:once) { good_definition_set }
          expect(File).to receive(:exists?).with(/secrets.yml/).once { true }
          expect(File).to receive(:read).with(/secrets.yml/).once { good_secrets_private }
          expect(File).to receive(:exists?).with(/secrets.edn/).once { true }
          expect(File).to receive(:read).with(/secrets.edn/).once { good_secrets_basic }
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

      context 'invalid_name config' do
        let(:config_name) { 'invalid' }
        it "returns config def for one yml file in the local config directory named invalid" do
          expect(config.logger).to receive(:warn)
          expect(config.config_defs.length).to eq 1
          expect(config.config_defs.map(&:keys).flatten).to eq([:yml])
          expect(config.config_defs.first[:yml][:local][:folder]).to eq('config')
          expect(config.config_defs.first[:yml][:local][:config_file_name]).to eq('invalid')
        end
      end
    end

    private

    def good_secrets_basic
      @good_secrets_basic ||= File.read('./spec/fixtures/config/secrets.edn')
    end

    def good_secrets_private
      @good_secrets_private ||= File.read('./spec/fixtures/config/.private/secrets.yml')
    end

    def good_definition_set
      @good_def_set ||= File.read('./spec/fixtures/config/load_sets.yml')
    end
  end
end
