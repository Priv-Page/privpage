require "http/client"

require "./github/oauth"
require "./github/session"
require "./user_repository"

# https://developer.github.com/apps/building-github-apps/identifying-and-authorizing-users-for-github-apps/
module GitHub
  extend self

  def handle_request(first_subdomain_part, root_domain, context : HTTP::Server::Context)
    if first_subdomain_part == "callback"
      return handle_callback root_domain, context
    end
    if user_repository = PrivPage::UserRepository.from_subdomain first_subdomain_part, context.response
      if session = Session.get_session?(context.request.cookies["github_session"]?.try &.value)
        session.get_page user_repository, context.request.path, context.response
      else
        state = OAuth::State.new user_repository.subdomain, context.request.path
        OAuth.request_identity_redirect state, context.response
      end
    end
    # The response should have already been sent at this point
  end

  # context.response.respond_with_status HTTP::Status::NOT_FOUND

  def handle_callback(root_domain, context : HTTP::Server::Context)
    context.response.print context.request.host
    code : String? = nil
    state : OAuth::State? = nil
    if request_query = context.request.query
      HTTP::Params.parse request_query do |query, value|
        case query
        when "code" then code = value
        when "state"
          state = OAuth::State.from_string value
          # Invalid UserRepository - stop
          break if !state
        else
        end
      end
    end
    if !code || !state
      context.response.respond_with_status HTTP::Status::BAD_REQUEST
    else
      token = state.get_access_token code
      Session.add state.random, token
      context.response.cookies << HTTP::Cookie.new(
        name: "github_session",
        domain: root_domain,
        value: state.random,
        http_only: true,
        secure: true,
      )
      full_path = "http://#{state.user_repository_subdomain}#{root_domain}#{state.path}"
      redirect full_path, context.response
    end
  end

  def redirect(path : String, response : HTTP::Server::Response)
    response.headers["location"] = path
    response << "Redirection: " << path
    response.status = HTTP::Status::TEMPORARY_REDIRECT
  end
end
