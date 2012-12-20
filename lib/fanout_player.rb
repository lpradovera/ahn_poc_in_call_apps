# encoding: utf-8

class FanoutPlayer < Adhearsion::CallController::Output::AbstractPlayer

  #
  # @yields The output component before executing it
  # @raises [PlaybackError] if (one of) the given argument(s) could not be played
  #
  def output(content, options = {})
    options.merge! :ssml => content.to_s

    calls = [controller.call] + controller.call.peers.values
    latch = CountDownLatch.new calls.count

    component = nil
    yielded = false
    calls.each do |call|
      component = new_output Marshal.load(Marshal.dump(options))

      unless yielded
        # Yield the first component so #listen prompts still work.
        # FIXME
        # Make sure we keep the first call in the array as the active user.
        # This will ensure his prompts are interrupted when he begins speaking.
        # As a side effect of this, the prompt will finish playing to the other connected
        # calls before this method returns. This should not surprise the callers ever,
        # but may leave them feeling like the system is sluggish when barging on prompts.
        # FIXME
        yield component if block_given?
        yielded = true
      end

      component.register_event_handler Punchblock::Event::Complete do |event|
        completion_event = event
        latch.countdown!
      end

      call.write_and_await_response component
    end

    latch.wait
    # This is somewhat non-deterministic
    component
  rescue Adhearsion::Call::Hangup
    raise
  rescue Adhearsion::Error, Punchblock::ProtocolError => e
    raise PlaybackError, "Output failed due to #{e.inspect}"
  end
end
