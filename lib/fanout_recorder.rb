class FanoutRecorder
  def initialize(controller)
    @controller = controller
  end

  def record(options = {})
    calls = [@controller.call] + @controller.call.peers.values
    latch = CountDownLatch.new calls.count

    results = {}

    component = nil
    yielded = false
    calls.each do |call|
      component = Punchblock::Component::Record.new Marshal.load(Marshal.dump(options))

      component.register_event_handler Punchblock::Event::Complete do |event|
        results[call.id] = component.recording_uri
        completion_event = event
        latch.countdown!
      end

      call.write_and_await_response component
    end

    latch.wait
    # This is somewhat non-deterministic
    results
  rescue Adhearsion::Call::Hangup
    raise
  rescue Adhearsion::Error, Punchblock::ProtocolError => e
    raise Adhearsion::CallController::Record::RecordError, "Recording failed due to #{e.inspect}"
  end
end
