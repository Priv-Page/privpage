require "random/secure"
require "oauth2"
require "http/client"

module GitHub::OAuth
  protected class_getter client_id = ENV["GITHUB_OAUTH_CLIENT_ID"]
  protected class_getter client_secret = ENV["GITHUB_OAUTH_SECRET_ID"]

  @@url : String = "https://github.com/login/oauth/authorize?client_id=" + @@client_id

  def self.request_identity_redirect(state : State, response : HTTP::Server::Response)
    url = @@url + "&state=" + state.value
    GitHub.redirect url, response
  end

  # Protects against cross-site request forgery attacks.
  struct State
    getter random : String
    getter path : String
    getter user_repository_subdomain : String

    def initialize(@user_repository_subdomain : String, @path : String, @random : String = Random::Secure.urlsafe_base64)
    end

    @@access_token_body = "client_id=#{OAuth.client_id}&client_secret=#{OAuth.client_secret}"
    @@access_token_headers = HTTP::Headers{
      "accept"       => "application/json",
      "content-type" => "application/x-www-form-urlencoded",
    }

    # Returns an access token.
    def get_access_token(code : String) : String
      form = @@access_token_body + "&code=#{code}&state=#{value}"
      client = HTTP::Client.new("github.com", tls: true)
      client_response = client.post(
        "/login/oauth/access_token",
        form: form,
        headers: @@access_token_headers
      )
      client.close
      case client_response.status
      when .ok?, .created?
        OAuth2::AccessToken.from_json(client_response.body).access_token
      else
        raise OAuth2::Error.new(client_response.body)
      end
    end

    def value : String
      # '=' is never in used a urlsafe_base64
      "#{@random}=#{user_repository_subdomain}/#{@path}"
    end

    def self.from_string(str : String)
      random, _, subdomain_and_path = str.partition '='
      user_repository_subdomain, _, path = subdomain_and_path.partition '/'
      new user_repository_subdomain, path, random
    end
  end
end
