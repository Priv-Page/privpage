require "http/server"
require "log"
require "./user_repository"
require "./github"

module PrivPage
  extend self

  @@log = Log.new("server", Log::IOBackend.new(STDERR), :info)

  def proc(context : HTTP::Server::Context) : Nil
    # Enable cross-site filter (XSS) and tell browser to block detected attacks
    context.response.headers["X-XSS-Protection"] = "1; mode=block"
    # Prevent some browsers from MIME-sniffing a response away from the declared Content-Type
    context.response.headers["X-Content-Type-Options"] = "nosniff"
    # Disallow the site to be rendered within a frame (clickjacking protection)
    context.response.headers["X-Frame-Options"] = "DENY"

    # For now only GitHub is supported
    first_subdomain_part, root_domain = UserRepository.split_first_subdomain_part context.request.host.to_s
    GitHub.handle_request first_subdomain_part, root_domain, context
  rescue ex
    context.response.respond_with_status(:internal_server_error)
    @@log.warn(exception: ex) { }
  end

  def start(port : Int32)
    server = HTTP::Server.new [
      HTTP::LogHandler.new,
    ], &->proc(HTTP::Server::Context)
    address = server.bind_tcp port
    @@log.info { "Listening on http://#{address}" }
    server.listen
  end
end

PrivPage.start(ENV["PORT"]?.try(&.to_i) || 3000)
