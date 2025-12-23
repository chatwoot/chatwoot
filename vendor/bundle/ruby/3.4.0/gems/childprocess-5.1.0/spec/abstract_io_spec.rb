require File.expand_path('../spec_helper', __FILE__)

describe ChildProcess::AbstractIO do
  let(:io) { ChildProcess::AbstractIO.new }

  it "inherits the parent's IO streams" do
    io.inherit!

    expect(io.stdout).to eq STDOUT
    expect(io.stderr).to eq STDERR
  end
end
