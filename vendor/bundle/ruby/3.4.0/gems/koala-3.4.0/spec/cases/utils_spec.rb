require 'spec_helper'

describe Koala::Utils do
  describe ".deprecate" do    
    before :each do
      # unstub deprecate so we can test it
       allow(Koala::Utils).to receive(:deprecate).and_call_original
    end
    
    it "has a deprecation prefix that includes the words Koala and deprecation" do
      expect(Koala::Utils::DEPRECATION_PREFIX).to match(/koala/i)
      expect(Koala::Utils::DEPRECATION_PREFIX).to match(/deprecation/i)      
    end
    
    it "prints a warning with Kernel.warn" do
      message = Time.now.to_s + rand.to_s
      expect(Kernel).to receive(:warn)
      Koala::Utils.deprecate(message)
    end

    it "prints the deprecation prefix and the warning" do
      message = Time.now.to_s + rand.to_s
      expect(Kernel).to receive(:warn).with(Koala::Utils::DEPRECATION_PREFIX + message)
      Koala::Utils.deprecate(message)
    end
    
    it "only prints each unique message once" do
      message = Time.now.to_s + rand.to_s
      expect(Kernel).to receive(:warn).once
      Koala::Utils.deprecate(message)
      Koala::Utils.deprecate(message)
    end
  end
  
  describe ".logger" do
    it "has an accessor for logger" do
      expect(Koala::Utils.methods.map(&:to_sym)).to include(:logger)
      expect(Koala::Utils.methods.map(&:to_sym)).to include(:logger=)
    end
    
    it "defaults to the standard ruby logger with level set to ERROR" do |variable|
      expect(Koala::Utils.logger).to be_kind_of(Logger)
      expect(Koala::Utils.logger.level).to eq(Logger::ERROR)
    end
    
    logger_methods = [:debug, :info, :warn, :error, :fatal]
    
    logger_methods.each do |logger_method|
      it "should delegate #{logger_method} to the attached logger" do
        expect(Koala::Utils.logger).to receive(logger_method)
        Koala::Utils.send(logger_method, "Test #{logger_method} message")
      end
    end
  end
end