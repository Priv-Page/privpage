require "log"
require "oauth2"

struct PrivPage::Session(T)
  def initialize(io : IO = STDERR)
    @log = Log.new("session", Log::IOBackend.new(io), :info)
  end

  # Sessions with its data.
  @store = Hash(String, Tuple(Time, T)).new

  def size : Int32
    @store.size
  end

  # Store a new session.
  # It is advised to have a secure random session key.
  def add(key : String, session : T, time : Time = Time.utc) : T
    @store[key] = {time, session}
    session
  end

  # Starts the Session Garbage Collector in the background.
  def start_gc(interval : Time::Span, max_period : Time::Span)
    spawn do
      loop do
        sleep interval
        time = Time.utc
        max_time = time - max_period
        @log.info { "#{time} Cleaning all sessions older than #{max_time}..." }
        initial_size = size
        @store.reject! do |_, d|
          d.first < max_time
        end
        @log.info { "#{Time.utc} #{initial_size - size} objects removed on #{initial_size} objects presents." }
      end
    end
  end

  # Gets a session, if present.
  def get?(session_key : String?) : T?
    if session_key
      @store[session_key]?.try &.last
    end
  end
end
