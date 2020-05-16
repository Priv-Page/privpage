require "http/server/response"

# Represents an user repository transformed to a safe subdomain.
struct PrivPage::UserRepository
  getter user : String
  getter repository : String
  getter base_branch : String?
  getter subdomain : String
  # Delimiter between the user, repository and optionally, the branch.
  class_property delimiter : String = "--"
  # Base branch prefix to serve static pages.
  class_property branch_prefix = "privpage"

  # Full Git branch to be served.
  def full_branch : String
    if base_branch = @base_branch
      @@branch_prefix + '-' + base_branch
    else
      @@branch_prefix
    end
  end

  def initialize(@subdomain : String, @user : String, @repository : String, @base_branch : String? = nil)
  end

  def self.from_subdomain(first_subdomain_part : String, response : HTTP::Server::Response) : UserRepository?
    user = repository = branch = nil
    index = 0
    first_subdomain_part.split @@delimiter do |part|
      if index > 2
        response.status = HTTP::Status::BAD_REQUEST
        response.print "Missing user part in the subdomain."
        return
      elsif part.empty?
        response.status = HTTP::Status::FORBIDDEN
        response.print "Delimiter character '#{@@delimiter}' is forbidden."
        return
      elsif part.includes? '.'
        response.status = HTTP::Status::FORBIDDEN
        response.print "Dot character ('.') is forbidden: '#{part}'."
        return
      else
        case index
        when 0 then user = part
        when 1 then repository = part
        when 2 then branch = part
        else
        end
      end
      index += 1
    end

    if !user
      response.status = HTTP::Status::BAD_REQUEST
      response.print "Missing user part in the subdomain."
    elsif !repository
      response.status = HTTP::Status::BAD_REQUEST
      response.print "Missing repository part in the subdomain."
    else
      new first_subdomain_part, user, repository, branch
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
