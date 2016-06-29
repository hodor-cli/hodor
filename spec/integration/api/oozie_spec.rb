module Hodor
  describe Oozie do
    describe 'Required Public Interface' do
      subject { Hodor::Oozie.methods }

      # Public methods
      it { should include :job_by_id }
      it { should include :job_by_path }
      it { should include :change_job }
      it { should include :compose_job_file }
      it { should include :run_job }
    end

    context 'when running an Oozie job' do

      subject(:oozie) { Hodor::Oozie }
      let(:env) { Hodor::Environment.instance }

      context 'missing jobs.yml file' do

        before(:each) do
          use_settings hdfs_root: '/', hdfs_user: 'hdfs'
          use_pwd 'drivers/testbench', true
        end

        it 'should fail if no jobs.yml file exists' do
          allow(File).to receive(:exists?).once.with('jobs.yml') { |arg| false }
          expect {
            oozie.run_job('job_does_not_exist')
          }.to raise_error { |ex|
            expect(ex.message).to match(/No jobs.yml file exists/)
          }
        end
      end

      context 'and all required files are accessible' do
        let(:no_op_job_params) { %Q[
                  valid_job:
                    deploy: no_op
                    properties: |
                      startTime=2015-10-02T11:02Z
                      endTime=2016-10-21T12:45Z
                  ] }
        before(:each) do
          allow(File).to receive(:exists?).at_least(:once).and_wrap_original do |original, *args|
            if (args[0] =~ /jobs.yml$/)
              true
            else
              original.call(*args)
            end
          end
          use_pwd 'drivers/testbench'
        end

        subject(:env) { Hodor::Environment.instance }

        it 'should fail with useful error message if bad job id is specified' do
          expect(Hodor::Environment.instance).to receive(:yml_load).once
            .with(/drivers\/testbench\/jobs\.yml/).and_call_original

          allow(File).to receive(:read).at_least(:once)
              .and_wrap_original do |original, *args|
                if (args[0] =~ /jobs.yml$/)
                  %Q[
                  valid_job:
                    deploy: nosuch_worker
                    properties: |
                      startTime=2015-10-02T11:02Z
                      endTime=2016-10-21T12:45Z
                  ]
                else
                  original.call(*args)
                end
          end

          expect {
            oozie.run_job 'nosuch_job'
          }.to raise_error { |ex|
            expect(ex.message).to match(/Job 'nosuch_job' was not defined in jobs.yml/)
          }
        end

        context 'and a valid job id is specified' do

          before(:each) do
            expect(env).to receive(:secrets).once
            use_settings hdfs_root: '/', hdfs_user: 'hdfs',
                         ssh_host: 'sample_domain.com', ssh_user: 'job_user'
            use_pwd 'drivers/testbench', true
          end

          it 'should build the expected runjob file that correctly applies property overrides' do

            expect(env).to receive(:yml_load).once
              .with(/drivers\/testbench\/jobs\.yml/).and_call_original

            allow(File).to receive(:read).at_least(:once)
                .and_wrap_original do |original, *args|
                  if (args[0] =~ /jobs.yml$/)
                    %Q[
                      ^valid_job:
                        deploy: noop
                        properties: |
                          startTime=<dynamic>
                          endTime=<dynamic>
                    ]
                  else
                    original.call(*args)
                  end
            end

            expect(oozie).to receive(:compose_job_file).once.and_wrap_original do |original, *args|
              propfile = original.call(*args)
              expect(propfile).to match(/test_repo\/drivers\/testbench\/.tmp\/runjob.properties$/)
              contents = File.open(propfile, 'rb') { |f| f.read }
              expect(contents).to match(/shared_jars_dir=\/shared\/jars/)
              expect(contents).to match(/startTime=\<dynamic\>/)
              expect(contents).to match(/oozie\.coord\.application\.path=\$\{CWD\}/)
              expect(contents).to match(/queueName\=default/)
              expect(contents).to match(/test_property\s+\=\s+test_value/)
            end

            expect(env).to receive(:deploy_tmp_file).once { }
            expect(env).to receive(:ssh).once { }

            expect {
              oozie.run_job(nil, { test_property: "test_value" })
            }.not_to raise_error
          end

          it 'should change to new path before run_job, and restore original path when done' do
            expect(Hodor::Environment.instance).to receive(:yml_load).once
              .with(/drivers\/testbench\/jobs\.yml/).and_call_original

            allow(File).to receive(:read).at_least(:once)
                .and_wrap_original do |original, *args|
                  if (args[0] =~ /jobs.yml$/)
                    %Q[
                      ^valid_job:
                        deploy: noop
                        properties: |
                          startTime=<dynamic>
                          endTime=<dynamic>
                    ]
                  else
                    original.call(*args)
                  end
            end

            expect(env).to receive(:deploy_tmp_file).once { }
            expect(env).to receive(:ssh).once { }

            # File call to CD changes to child path
            expect(FileUtils).to receive(:cd).once.and_wrap_original do |original, *args|
              expect(args[0]).to match(/some\/new\/path/);
            end

            # Second call to CD restores original path
            expect(FileUtils).to receive(:cd).once.and_wrap_original do |original, *args|
              expect(args[0]).to match(/test_repo/);
            end

            expect {
              oozie.run_job(nil, { 
                pushd: 'some/new/path'
              })
            }.not_to raise_error
          end

          it 'should deploy and run the Oozie job' do
            expect(env).to receive(:yml_load).once
              .with(/drivers\/testbench\/jobs\.yml/).and_call_original

            allow(File).to receive(:read).at_least(:once)
                .and_wrap_original do |original, *args|
                  if (args[0] =~ /jobs\.yml$/)
                    no_op_job_params
                  else
                    original.call(*args)
                  end
            end

            expect(oozie).to receive(:compose_job_file).once.and_call_original
            expect(env).to receive(:run_local).once
              .with(/scp.*drivers\/testbench\/.tmp\/runjob.properties\sjob_user\@sample_domain.*:\/tmp\/runjob.*properties.*/,
                                                         { echo: true, echo_cmd: true }) { }
            expect(env).to receive(:run_local).once.with(/oozie\sjob.*\/tmp\/runjob.*properties.*-run$/,
                                                         { echo: true, echo_cmd: true, ssh: true }) { }
            expect {
              oozie.run_job 'valid_job'
            }.not_to raise_error
          end

          context 'dry_run option is set to true' do
            it 'generates properties file but should not deploy and run the Oozie job' do
              expect(env).to receive(:yml_load).once
                                                         .with(/drivers\/testbench\/jobs\.yml/).and_call_original

              allow(File).to receive(:read).at_least(:once)
                                 .and_wrap_original do |original, *args|
                if (args[0] =~ /jobs\.yml$/)
                  no_op_job_params
                else
                  original.call(*args)
                end
              end

              expect(oozie).to receive(:compose_job_file).once.and_call_original
              expect(env).not_to receive(:run_local)
              expect {
                oozie.run_job('valid_job', dry_run: true)
              }.not_to raise_error
            end
          end

          context 'dry_run option is set to true and file prefix included' do
            let(:prefix) { 'zywxqrts_pre_' }
            it 'generates properties file with prefix appended but does not deploy and run the Oozie job' do
              expect(Hodor::Environment.instance).to receive(:yml_load).once
                                                         .with(/drivers\/testbench\/jobs\.yml/).and_call_original

              allow(File).to receive(:read).at_least(:once)
                                 .and_wrap_original do |original, *args|
                if (args[0] =~ /jobs\.yml$/)
                  no_op_job_params
                else
                  original.call(*args)
                end
              end

              expect(oozie).to receive(:compose_job_file).once.with(
                hash_including(name: 'valid_job'),
                hash_including(dry_run: true, file_prefix: prefix))
                .and_call_original
              expect(env).not_to receive(:run_local)
              expect(oozie.run_job('valid_job', dry_run: true, file_prefix: prefix)).to match(prefix)
            end
          end
        end
      end
    end
  end
end
