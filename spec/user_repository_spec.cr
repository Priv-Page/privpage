require "spec"
require "../src/user_repository"

SPEC_RESPONSE = HTTP::Server::Response.new IO::Memory.new

def assert_user_repository(subdomain, user, repository, branch = nil, file = __FILE__, line = __LINE__)
  it "parses #{subdomain}", file, line do
    user_repo = PrivPage::UserRepository.from_subdomain subdomain, SPEC_RESPONSE
    user_repo.should be_a PrivPage::UserRepository
    if user_repo.is_a? PrivPage::UserRepository
      user_repo.user.should eq user
      user_repo.repository.should eq repository
      user_repo.base_branch.should eq branch
    else
      fail "expected #{PrivPage::UserRepository}"
    end
  end
end

def assert_fail_parse_user_repository(subdomain, file = __FILE__, line = __LINE__)
  it "fails to parse #{subdomain}", file, line do
    result = PrivPage::UserRepository.from_subdomain subdomain, SPEC_RESPONSE
    result.should be_nil
  end
end

describe PrivPage::UserRepository do
  describe "from_subdomain" do
    assert_user_repository "user--repo", "user", "repo"
    assert_user_repository "user---repo", "user", "-repo"
    assert_user_repository "user---re-po", "user", "-re-po"
    assert_user_repository "user--repo--branch", "user", "repo", "branch"
    assert_user_repository "user--repo---branch", "user", "repo", "-branch"

    assert_fail_parse_user_repository "user--repo--branch--other"
    assert_fail_parse_user_repository "user----repo"
    assert_fail_parse_user_repository "user--repo--"
    assert_fail_parse_user_repository "user--repo."
    assert_fail_parse_user_repository "user--"
    assert_fail_parse_user_repository "--repo"
    assert_fail_parse_user_repository "--"
  end

  describe ".split_first_subdomain_part" do
    it "splits successfully" do
      PrivPage::UserRepository.split_first_subdomain_part(
        "sub.git.example.com").should eq({"sub", ".git.example.com"})
      PrivPage::UserRepository.split_first_subdomain_part(
        "one.two.sub.git.example.com").should eq({"one.two.sub", ".git.example.com"})
    end
  end
end
