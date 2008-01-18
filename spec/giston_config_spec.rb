require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A new Giston::Config" do
  before(:each) do
    YAML.stub!(:load_file).and_return([])
    @config = Giston::Config.new
  end
  
  it "should be empty" do
    @config = Giston::Config.new

    @config.mirrors.should be_empty
  end
end

describe "Giston::Config" do
  before(:each) do
    YAML.should_receive(:load_file).and_return([{"dir" => "local/dir", "url" => "remote/path", "rev" => "4"}])
    @config = Giston::Config.new
  end

  it "should check for existance of mirror by dir" do
    @config.should have_item("local/dir")
    @config.should_not have_item("local/newdir")
  end

  it "should raise when trying to add a duplicate mirror" do
    lambda { @config.add({"dir" => "local/dir", "url" => "remote/path", "rev" => "4"}) }.should raise_error(Giston::Config::MirrorNameAlreadyInUse)
    lambda { @config.add({"dir" => "local/dir/", "url" => "remote/path", "rev" => "4"}) }.should raise_error(Giston::Config::MirrorNameAlreadyInUse)
  end

  it "should add a new mirror if it doesn't exist" do
    File.should_receive(:open).twice
    @config.add({"dir" => "local/newdir", "url" => "remote/newpath", "rev" => "13"})
    @config.mirrors.length.should == 2
    @config.add({"dir" => "local/anothernewdir/", "url" => "remote/anothernewpath", "rev" => "13"})
    @config.mirrors.length.should == 3
  end

  it "should raise when trying to remove a nonexistig mirror" do
    lambda { @config.remove("local/newdir") }.should raise_error(Giston::Config::MirrorDoesNotExist)
    lambda { @config.remove("local/newdir/") }.should raise_error(Giston::Config::MirrorDoesNotExist)
  end

  it "should remove an existing mirror" do
    File.should_receive(:open)
    @config.remove("local/dir")
    @config.mirrors.length.should == 0
  end

  it "should remove an existing mirror ignoring ending slash" do
    File.should_receive(:open)
    @config.remove("local/dir/")
    @config.mirrors.length.should == 0
  end

  it "should get a mirror given it's name" do
    mirror = @config.get("local/dir")
    mirror["url"].should == "remote/path"
    mirror = @config.get("local/dir/")
    mirror["url"].should == "remote/path"
  end

  it "should get a mirror given a mirror (any hash with a dir key)" do
    mirror = @config.get({"dir" => "local/dir"})
    mirror["url"].should == "remote/path"
    mirror = @config.get({"dir" => "local/dir/"})
    mirror["url"].should == "remote/path"
  end

  it "should raise when trying to update a nonexisting mirror" do
    lambda { @config.update("local/nonexistent", {"dir" => "local/nonexistent", "url" => "remote/path", "rev" => "13"}) }.should raise_error(Giston::Config::MirrorDoesNotExist)
  end

  it "should remove existing mirror and ad the new one when updating with valid parameters" do
    @config.should_receive(:remove).with("local/dir")
    @config.should_receive(:add).with({"dir" => "local/newdir", "url" => "remote/newpath", "rev" => "13"})

    @config.update("local/dir", {"dir" => "local/newdir", "url" => "remote/newpath", "rev" => "13"}) 
  end

end
