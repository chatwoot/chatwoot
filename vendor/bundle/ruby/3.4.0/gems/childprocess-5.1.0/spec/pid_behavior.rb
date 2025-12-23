require File.expand_path('../spec_helper', __FILE__)

shared_examples_for "a platform that provides the child's pid" do
  it "knows the child's pid" do
    Tempfile.open("pid-spec") do |file|
      process = write_pid(file.path).start
      process.wait

      expect(process.pid).to eq rewind_and_read(file).chomp.to_i
    end
  end
end
