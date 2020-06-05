require "spec"
require "../src/session"

describe PrivPage::Session do
  it "adds a session" do
    session = PrivPage::Session(String).new
    session.add("1", "session").should eq "session"
    session.size.should eq 1
  end

  it "gets a session" do
    session = PrivPage::Session(String).new
    session.add "1", "session"
    session.get?("1").should eq "session"
  end

  it "gets no session" do
    session = PrivPage::Session(String).new
    session.get?("1").should be_nil
  end

  describe "garbage collecter" do
    it "removes old sessions" do
      session = PrivPage::Session(String).new File.open File::NULL, "w"
      time = Time.utc
      session.add "1", "session", time: time - 2.days
      session.start_gc interval: 0.days, max_period: 1.days
      sleep 0.1
      session.size.should eq 0
    end

    it "keeps sessions not old enough" do
      session = PrivPage::Session(String).new File.open File::NULL, "w"
      time = Time.utc
      session.add "1", "session", time: time
      session.start_gc interval: 0.days, max_period: 1.days
      sleep 0.1
      session.size.should eq 1
    end
  end
end
