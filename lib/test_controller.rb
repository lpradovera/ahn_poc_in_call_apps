# encoding: utf-8

class TestController < Adhearsion::CallController
  def run
    answer
    dtmf_comp = Punchblock::Component::Input.new :mode => :dtmf,
      :grammar => {
      :value => grammar_accept('0123456789#*')
    }
    dtmf_comp.register_event_handler Punchblock::Event::Complete do |event|
      logger.info "DTMF DETECTED"
      play_broadcast "#{Adhearsion.config.platform[:root]}/hey.wav"
      recs = fanout_recorder.record :max_duration => 10
      logger.info "RECORDINGS: #{recs}"
    end
    call.write_and_await_response dtmf_comp
    dial "user/1002"
    #dial "sofia/internal/1002@domain=li452-124.members.linode.com"
    #dial "sofia/internal/1002@176.58.102.124"
    #play "#{Adhearsion.config.platform[:root]}/hey.wav"
  end

  def play_broadcast(*arguments)
    fanout_player.play_ssml output_formatter.ssml_for_collection(arguments)
    true
  end

  def fanout_player
    @fanout_player ||= FanoutPlayer.new(self)
  end

  def fanout_recorder
    @fanout_recorder ||= FanoutRecorder.new(self)
  end
end
