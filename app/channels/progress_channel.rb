# app/channels/progress_channel.rb
class ProgressChannel < ApplicationCable::Channel
  def subscribed
    stream_from "progress_channel"
  end
end
