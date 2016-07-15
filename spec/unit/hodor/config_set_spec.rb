require 'hodor/config_set'

module Hodor

  describe ConfigSet do

    describe "Required Class Methods" do
      subject(:config) { Hodor::ConfigSet.methods  }

      it { should include :config_definitions_sets }
      it { should include :has_required_tag? }
      it { should include :check_for_missing_configs }
      it { should include :missing_properties_error }
      it { should include :missing_configs }
    end

    context "Test reading config definition sets " do
      subject { ConfigSet.config_definitions_sets }
      it "returns hash containing order collection of load sets for each configuration" do
        good_definition_set
        expect(File).to receive(:exists?).with(/load_sets.yml/).once { true }
        expect(File).to receive(:read).with(/load_sets.yml/).once { good_definition_set }
        results = subject.config_hash
        expect(results.length).to eq 6
        expect(results.keys).to eq([:secrets, :clusters, :egress, :secrets_override, :clusters_bad, :clusters_good])
        expect(results[:clusters]).to be_kind_of(Hash)
        expect(results[:clusters].keys).to eq([:on_required_missing,:sources])
        expect(results[:clusters][:sources]).to be_kind_of(Array)
        expect(results[:clusters][:sources].length).to eq 3
        expect(results[:clusters][:on_required_missing]).to eq :warn
      end
    end

    context "Test checking for required properties" do
      subject { ConfigSet.check_for_missing_configs(tst_hash, on_required_missing_do) }
      context "Hash missing required properties"  do
        let(:tst_hash) { { missing1: "#required missing1", inner_hash: { missing_inner: "#required inner", present: "okay"} }}
        let(:missing_message) { 'Missing properties: missing1 #required missing1; missing_inner #required inner.' }

        context "fail on missing" do
          let(:on_required_missing_do) { :fail }
          it "Raises and error" do
            expect {subject}.to raise_error(RuntimeError, missing_message)
          end
        end

        context "warn on missing" do
          let(:on_required_missing_do) { :warn }
          it "Warns with error message error" do
            expect(ConfigSet.logger).to receive(:warn)
            subject
          end
        end

        context "ignore on missing" do
          let(:on_required_missing_do) { :debug }
          it "Warns with error message error" do
            expect(ConfigSet.logger).to_not receive(:debug)
            expect(subject.nil?)
          end
        end
      end

      context "Hash with no missing required properties"  do
        let(:tst_hash) { { missing1: "all goo", inner_hash: { missing_inner: "all goo", present: "okay"} }}

        context "no failure" do
          let(:on_required_missing_do) { :fail }
          it "Does not raise an error" do
            expect {subject}.to_not raise_error(RuntimeError)
          end
        end

        context "no warning" do
          let(:on_required_missing_do) { :warn }
          it "nothing missing" do
            expect(ConfigSet.logger).to_not receive(:warn)
            subject
          end
        end
      end
    end

    describe 'constants' do
      it 'should return correct constants' do
        expect(Hodor::ConfigSet::LOAD_SETS_FILE_SPECIFICATION).to eq({ yml:
                                                                           { local:
                                                                                 { folder: "config",
                                                                                   config_file_name: "load_sets" }}})
      end
    end

    describe "Required Public Interface" do

      subject(:config) { Hodor::ConfigSet.instance_methods }

      # Public methods
      it { should include :logger }
      it { should include :env }
      it { should include :config_defs }
      it { should include :load }
      it { should include :config_sets }
      it { should include :process }
      it { should include :config_hash }
      it { should include :config_name }
      it { should include :load_config_source }
      it { should include :on_required_missing }
    end

    describe "Instance methods" do

      subject(:config) { Hodor::ConfigSet.new(config_name) }

      context 'secrets config' do
        let(:config_name) { 'secrets' }

        it "returns config defs " do
          expect(config.config_defs.length).to eq 2
          expect(config.config_defs.map(&:keys).flatten).to eq([:edn, :yml])
        end

        it "returns a set of configs of the correct class " do
          expect(config.config_sets.length).to eq 2
          expect(config.config_sets.map(&:class).map(&:name)).to eq(['Hodor::Config::EdnSource',
                                                                     'Hodor::Config::YmlSource',])
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
          expect(config.config_hash).to eq({ test: { all_props:{ test_prop: { test_key: "test value",
                                                                                 test_key1: "test value1" }}}})

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

    describe "Required properties" do

      subject(:config) { Hodor::ConfigSet.new(config_name) }

      context 'Missing properties' do
        let(:config_name) { 'secrets_override' }
        let(:missing_secrets) {"Missing properties: test_key_o #required talk to sys ops if you don't know this value."}
        it "raises an error" do
          override_secrets_yml
          good_secrets_private

          expect(File).to receive(:exists?).with(/secrets_override.yml/).once { true }
          expect(File).to receive(:read).with(/secrets_override.yml/).once { override_secrets_yml }
          expect(File).to receive(:exists?).with(/secrets.yml/).once { true }
          expect(File).to receive(:read).with(/secrets.yml/).once { good_secrets_private }
          expect {config.config_hash}.to raise_error(RuntimeError, missing_secrets)
        end
      end

      context 'Missing in edn clusters file' do
        let(:config_name) { 'clusters_bad' }
        let(:missing_cluster_configs) {'Missing properties: '+
                                        'nameNode #required this must be defined in order for the app to work; '+
                                        'fakeNode #required to make the test fail twice.'}
        it "raises an error" do
          override_clusters_edn
          clusters_yml
          expect(File).to receive(:exists?).with(/clusters_override.edn/).once { true }
          expect(File).to receive(:read).with(/clusters_override.edn/).once { override_clusters_edn }
          expect(File).to receive(:exists?).with(/clusters.yml/).once { true }
          expect(File).to receive(:read).with(/clusters.yml/).once { clusters_yml }
          expect {config.config_hash}.to raise_error(RuntimeError, missing_cluster_configs)
        end
      end
    end

    describe "loading a config source" do
      subject { Hodor::ConfigSet.new('tst').load_config_source('tst', path_def)  }

      context "edn format type" do
        let(:path_def) { { edn: { tst: 'tst' }} }
        it { should be_kind_of(Hodor::Config::EdnSource) }
      end

      context "yml format type" do
        let(:path_def) { { yml: { tst: 'tst' }} }
        it { should be_kind_of(Hodor::Config::YmlSource) }
      end

      context "bad format type" do
        let(:path_def) { { bad_format: { tst: 'tst' }} }
        it "raises a not implemented error" do
          expect {subject}.to raise_error(NotImplementedError, "Bad Format is not a supported format")
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

    def override_secrets_yml
      @override_secrets_yml ||= File.read('./spec/fixtures/config/secrets_override.yml')
    end

    def override_clusters_edn
      @override_clusters_edn ||= File.read('./spec/fixtures/config/clusters_override.edn')
    end

    def clusters_yml
      @clusters_yml ||= File.read('./spec/fixtures/config/clusters.yml')
    end
  end
end
