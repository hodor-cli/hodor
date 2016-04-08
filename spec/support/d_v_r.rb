
class RSpec::Mocks::MessageExpectation
  def and_mimic_original(dvr)
    and_wrap_original do |original, *args|
      if dvr.recording?
        dvr.record(original.call(*args))
      else
        dvr.playback
      end
    end
  end
end

class DVR

  attr_accessor :playback_stdout

  def initialize(example)

    if example.methods.include?(:scenario)
      @mode = :playback
      @scenario = example.scenario
    end

    if example.methods.include?(:record)
      @mode = :record
      @scenario = example.record
    end

    if example.methods.include?(:playback)
      @mode = :playback
      @scenario = example.playback
    end
    @callno = 0
    @playback_stdout = false
  end

  def recording?
    @mode == :record
  end

  # Return the fixture data associated with a numbered request/response.
  def playback
    calling_module, call_stack = select_call_stack
    fix_file = File.join(root_dir, 'spec', 'integration', 'fixtures', calling_module,
                         @scenario.to_s, "req_resp_#{"%02d" % @callno}.memo")
    @callno += 1
    output = File.open(fix_file).inject("") do |memo, line|
      memo << line unless line.start_with?('#')
      memo
    end

    puts output if playback_stdout
    output
  end

  # Use a proxy to intercept the RESTful API call or SSH command line and grab the
  # actual response from the live call. Then save this artifact as a fixture. A
  # header/comment is added to this fixture to indicate the code path that led
  # to the creation of the current fixture.
  def record response
    calling_module, call_stack = select_call_stack
    fix_file = File.join(root_dir, 'spec', 'integration', 'fixtures', calling_module,
                         @scenario.to_s, "req_resp_#{"%02d" % @callno}.memo")
    @callno += 1
    FileUtils.mkdir_p(File.dirname(fix_file))
    File.open(fix_file, 'w') { |f|
      f.puts("# #{calling_module} - Call Stack Signature:")
      call_stack.each { |code_path| f.puts(code_path) }
      f.puts(response)
      response
    }
    puts response if playback_stdout
    response
  end

  private

  def root_dir
    @root ||= File.expand_path( File.join('..', '..'), File.dirname(__FILE__) )
  end

  # This function both selects which stack frames are relevant to display
  # in the header, and formats the stack frames it selects. Only the stack
  # frames in "my code" are selected and formatted. For brevity, stack
  # frames occurring in gems are omitted.
  def format_stack_frame(frame)
    if frame.path.start_with?(root_dir)
      path = frame.path[root_dir.length+1..-1]
      "#\t#{frame.label}()@#{path}:#{frame.lineno}"
    else
      nil
    end
  end

  def calling_spec_module(call_stack)
    if call_stack.length > 0
      call_stack.each { |frame|
        if frame =~ /spec\/integration\//
          caller_match = frame.match(/spec\/integration\/(\w+)\//)
          if !caller_match.nil?
            caller_captures = caller_match.captures
            return caller_captures.length > 0 ? caller_captures[0] : nil
          end
        end
      }
    end
    nil
  end

  def select_call_stack
    call_stack = []
    caller_locations.each_with_index { |frame, index|
      code_path = format_stack_frame(frame)
      call_stack << code_path if code_path
    }
    scrubbed_call_stack = call_stack.drop_while { |frame| 
      frame.include?('spec/support/d_v_r.rb')
    }
    return calling_spec_module(scrubbed_call_stack), scrubbed_call_stack
  end

end


