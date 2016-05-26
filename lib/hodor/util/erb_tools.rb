require 'erb'

module Hodor

  module ErbTools
    def erb_sub(erb_body)
      ERB.new(erb_body).result(self.instance_eval { binding })
    end

    def erb_load(filename, suppress_erb=false)
      if File.exists?(filename)
        file_contents = File.read(filename)
        sub_content = suppress_erb ? file_contents : erb_sub(file_contents)
        sub_content
      elsif !filename.start_with?(root)
        erb_load(File.join(root, filename))
      end
    end
  end
end



