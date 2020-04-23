require "oauth2"
require "./session_data"

module GitHub::Session
  start_gc interval: 1.hour, max_period: 2.days
  # Sessions with its data.
  @@store = Hash(String, Data).new

  # Store a new session.
  def self.add(random_session_key : String, access_token : String) : Data
    data = Data.new access_token
    @@store[random_session_key] = data
  end

  # Session Garbage Collector
  def self.start_gc(interval : Time::Span, max_period : Time::Span)
    spawn do
      loop do
        sleep interval
        time = Time.utc
        max_time = time + max_period
        STDERR << time
        STDERR.puts " Cleaning all sessions older than #{max_time}..."
        initial_size = @@store.size
        @@store.reject! do |_, d|
          d.time < max_time
        end
        STDERR << Time.utc
        STDERR.puts " #{initial_size - @@store.size} objects removed on #{@@store.size} objects presents."
      end
    end
  end

  # Gets a data session, if present.
  def self.get_session?(session_key : String?) : Data?
    if session_key
      @@store[session_key]?
    end
  end
end
