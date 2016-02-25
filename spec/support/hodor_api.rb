require 'hodor/api/oozie/session'

shared_context "hodor api" do

  attr_reader :memo

  subject(:env) { ::Hodor::Environment.instance }
  subject(:session) { ::Hodor::Oozie::Session.instance }
  subject(:oozie) { ::Hodor::Oozie }

  before(:each) do
    @memo = DVR.new(self) unless (self.methods & [:scenario, :playback, :record]).empty?
  end

end
