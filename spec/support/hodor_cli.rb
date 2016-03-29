shared_context "hodor cli" do

  attr_reader :memo

  before(:each) do
    @memo = DVR.new(self) unless (self.methods & [:scenario, :playback, :record]).empty?
  end

  # A struct to wrap the 3 return values of a shell command,
  # so that a let(:outcome) statement can return all 3 values.
  CheckResult = Struct.new(:exception, :stdout, :stderr) do
    def completed?
      exception.nil? || (exception.is_a?(SystemExit) && exception.message =~ /exit/)
    end

    def is_ok?
      exception.nil? || (exception.is_a?(SystemExit) && exception.status == 0 && exception.message =~ /exit/)
    end

    def is_warning?
      !exception.nil?
    end

    def is_critical?
      !exception.nil? && exception.is_a?(SystemExit) && exception.status == 1 && exception.message =~ /exit/
    end
  end unless defined?(CheckResult)

  def verbose?
    verbose
  end

  let(:result) { 
    $thor_runner = true
    $hodor_runner = true
    if verbose?
      puts "\n------------------------------------------------"
      puts " $ #{run}"
    end
    exception = nil
    @memo.playback_stdout = true if @memo
    stdout, stderr = capturing(:stdout, :stderr) {
      exception = rescuing { Hodor::Cli::Runner.start(run.split) }
    }
    @memo.playback_stdout = false if @memo
    if verbose?
      puts stdout if stdout.size > 0
      puts stderr if stderr.size > 0
      puts "------------------------------------------------"
    end
    raise exception if !exception.nil? && !exception.is_a?(SystemExit)
    CheckResult.new(exception, stdout, stderr)
  }
end


