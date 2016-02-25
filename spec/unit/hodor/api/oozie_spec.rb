module Hodor
  describe Oozie do
    describe 'Required Public Interface' do
      subject { Hodor::Oozie }

      # Public methods
      it { should respond_to? :job_by_id }
      it { should respond_to? :job_by_path }
      it { should respond_to? :change_job }
      it { should respond_to? :compose_job_file }
      it { should respond_to? :run_job }
    end
    context 'Filename prefixes' do
      let(:prefix) { 'Test_prefix_' }
      let(:full_path) { 'foo/foo/foo' }
      let(:just_name_path) { 'foo' }
      let(:correctly_prefixed) { 'foo/foo/Test_prefix_foo' }

      it 'appends a supplied prefix to the file name' do
         expect(subject.append_prefix_to_filename(full_path, prefix)).to eq(correctly_prefixed)
      end

      it 'appends a supplied prefix to a simple file name' do
        expect(subject.append_prefix_to_filename(just_name_path, prefix)).to eq(prefix+just_name_path)
      end

      it 'keeps original filename if no prefix supplied' do
        expect(subject.append_prefix_to_filename(full_path)).to eq(full_path)
      end
    end
  end
end
