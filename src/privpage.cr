require "http/server"
require "./user_repository"
require "./github"

module PrivPage
  extend self

  def proc(context : HTTP::Server::Context) : Nil
    context.response.headers["Content-Security-Policy"] = "default-src 'self'"
    # Enable cross-site filter (XSS) and tell browser to block detected attacks
    context.response.headers["X-XSS-Protection"] = "1; mode=block"
    # Prevent some browsers from MIME-sniffing a response away from the declared Content-Type
    context.response.headers["X-Content-Type-Options"] = "nosniff"
    # Disallow the site to be rendered within a frame (clickjacking protection)
    context.response.headers["X-Frame-Options"] = "DENY"

    # For now only GitHub is supported
    first_subdomain_part, root_subdomain = UserRepository.split_first_subdomain_part context.request.host.to_s
    GitHub.handle_request first_subdomain_part, root_subdomain, context
  end

  def start(port : Int32)
    server = HTTP::Server.new [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
    ], &->proc(HTTP::Server::Context)
    address = server.bind_tcp port
    puts "Listening on http://#{address}"
    server.listen
  end
end

PrivPage.start(ENV["PORT"]?.try(&.to_i) || 3000)
