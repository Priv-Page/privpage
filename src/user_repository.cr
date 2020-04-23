require "http/server/response"

# Represents an user repository transformed to a safe subdomain.
struct PrivPage::UserRepository
  getter user : String
  getter repository : String
  getter subdomain : String

  def initialize(@subdomain : String, @user : String, @repository : String)
  end

  def self.from_subdomain(first_subdomain_part : String, response : HTTP::Server::Response) : UserRepository?
    user, _, repo = first_subdomain_part.rpartition "--"

    if user.empty? || repo.empty?
      response.status = HTTP::Status::BAD_REQUEST
      response.print "Invalid user/repository: #{user}--#{repo}"
    elsif user.includes?("--")
      response.status = HTTP::Status::FORBIDDEN
      response.print "User containing forbidden characters ('--'): #{user}"
    elsif repo.includes?('.')
      response.status = HTTP::Status::FORBIDDEN
      response.print "Repository name cannot contain a dot ('.'): #{repo}"
    else
      new first_subdomain_part, user, repo
    end
  end

  class_property subdomains_count : Int32 = 3

  def self.split_first_subdomain_part(host : String) : Tuple(String, String)
    offset = host.size - 1
    @@subdomains_count.times do
      new_offset = host.rindex '.', offset
      break if !new_offset
      offset = new_offset - 1
    end
    {host[..offset], host[offset + 1..]}
  end
end
