require "http/client"
require "json"

struct GitHub::Session::Data
  getter token : String
  getter time : Time

  def initialize(@token : String)
    @time = Time.utc
  end

  # Gets the content of a path.
  def get_page(user_repository : PrivPage::UserRepository, path : String, response : HTTP::Server::Response) : Nil
    repo_url = "/repos/#{user_repository.user}/#{user_repository.repository}"
    headers = HTTP::Headers{"authorization" => "token " + @token}

    client = HTTP::Client.new "api.github.com", tls: true

    begin
      repo_response = client.get repo_url, headers

      if repo_response.status.ok?
        # No need to serve public repositories
        json = JSON::PullParser.new repo_response.body
        private_repo = false
        json.on_key "private" do
          private_repo = json.read_bool
        end

        if private_repo
          if path.empty? || path == "/"
            path = "/index.html"
            extension = ".html"
          else
            extension = Path.new(path).extension
          end

          if extension == ".md" || extension == ".rst"
            headers["accept"] = "application/vnd.github.v3.html"
            response.content_type = "text/html; charset=utf-8"
          else
            headers["accept"] = "application/vnd.github.v3.raw"
            if extension == ".html"
              response.content_type = "text/html; charset=utf-8"
            else
              response.content_type = MIME.from_extension?(extension) || "text/plain; charset=utf-8"
            end
          end

          content_url = repo_url + "/contents#{path}?ref=#{user_repository.full_branch}"
          client_response = client.get content_url, headers: headers
          response.status = client_response.status
          response << client_response.body
        else
          response.status = HTTP::Status::FORBIDDEN
          response.print "Public repositories not served."
        end
      else
        response.status = repo_response.status
        response.print "Invalid repository: #{user_repository.user}/#{user_repository.repository} (#{repo_response.status_message})."
      end
    ensure
      client.close
    end
  end
end
