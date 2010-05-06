require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "RedisCache" do
  before(:each) do
    @rcache = ActiveSupport::Cache::RedisCache.new
    @rabbit = OpenStruct.new :name => "bunny"
    @white_rabbit = OpenStruct.new :color => "white"
    @rcache.write  "rabbit", @rabbit
    @rcache.delete "counter"
    @rcache.delete "rub-a-dub"
    
  end
  it "should read the data" do
    @rcache.read("rabbit").should === @rabbit
  end

  it "should write the data" do
    @rcache.write "rabbit", @white_rabbit
    @rcache.read("rabbit").should === @white_rabbit
  end
end