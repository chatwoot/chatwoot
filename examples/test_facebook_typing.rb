#!/usr/bin/env ruby
# Test script để kiểm tra Facebook Typing Indicator Service

# Thêm đường dẫn để load Rails environment
require_relative '../config/environment'

class FacebookTypingTest
  def initialize
    @test_results = []
  end

  def run_all_tests
    puts "🧪 Bắt đầu test Facebook Typing Indicator Service..."
    puts "=" * 60
    
    test_service_initialization
    test_valid_actions
    test_channel_validation
    
    puts "\n" + "=" * 60
    puts "📊 Kết quả test:"
    @test_results.each_with_index do |result, index|
      status = result[:passed] ? "✅ PASS" : "❌ FAIL"
      puts "#{index + 1}. #{status} - #{result[:name]}"
      puts "   #{result[:message]}" unless result[:passed]
    end
    
    passed_count = @test_results.count { |r| r[:passed] }
    total_count = @test_results.count
    puts "\n🎯 Tổng kết: #{passed_count}/#{total_count} tests passed"
  end

  private

  def test_service_initialization
    test_name = "Service Initialization"
    
    begin
      # Tạo mock channel
      channel = OpenStruct.new(
        page_id: 'test_page_id',
        page_access_token: 'test_token',
        class: Channel::FacebookPage
      )
      
      service = Facebook::TypingIndicatorService.new(channel, 'test_recipient_id')
      
      if service.channel == channel && service.recipient_id == 'test_recipient_id'
        add_test_result(test_name, true, "Service khởi tạo thành công")
      else
        add_test_result(test_name, false, "Service khởi tạo thất bại")
      end
    rescue => e
      add_test_result(test_name, false, "Lỗi khởi tạo: #{e.message}")
    end
  end

  def test_valid_actions
    test_name = "Valid Actions Check"
    
    begin
      channel = OpenStruct.new(
        page_id: 'test_page_id',
        page_access_token: 'test_token'
      )
      channel.define_singleton_method(:is_a?) { |klass| klass == Channel::FacebookPage }
      channel.define_singleton_method(:present?) { true }
      
      service = Facebook::TypingIndicatorService.new(channel, 'test_recipient_id')
      
      valid_actions = ['typing_on', 'typing_off', 'mark_seen']
      invalid_actions = ['invalid_action', 'TYPING_ON', '']
      
      valid_results = valid_actions.all? { |action| service.send(:valid_action?, action) }
      invalid_results = invalid_actions.none? { |action| service.send(:valid_action?, action) }
      
      if valid_results && invalid_results
        add_test_result(test_name, true, "Validation actions hoạt động chính xác")
      else
        add_test_result(test_name, false, "Validation actions không chính xác")
      end
    rescue => e
      add_test_result(test_name, false, "Lỗi test validation: #{e.message}")
    end
  end

  def test_channel_validation
    test_name = "Channel Validation"
    
    begin
      # Test valid channel
      valid_channel = OpenStruct.new(
        page_id: 'test_page_id',
        page_access_token: 'test_token'
      )
      valid_channel.define_singleton_method(:is_a?) { |klass| klass == Channel::FacebookPage }
      valid_channel.define_singleton_method(:present?) { true }
      
      service = Facebook::TypingIndicatorService.new(valid_channel, 'test_recipient_id')
      
      if service.send(:valid_channel?)
        add_test_result(test_name, true, "Channel validation hoạt động chính xác")
      else
        add_test_result(test_name, false, "Valid channel bị từ chối")
      end
      
      # Test invalid channel
      invalid_service = Facebook::TypingIndicatorService.new(nil, 'test_recipient_id')
      
      unless invalid_service.send(:valid_channel?)
        puts "   ✓ Invalid channel được từ chối đúng cách"
      else
        add_test_result(test_name, false, "Invalid channel không được từ chối")
      end
      
    rescue => e
      add_test_result(test_name, false, "Lỗi test channel validation: #{e.message}")
    end
  end

  def add_test_result(name, passed, message)
    @test_results << {
      name: name,
      passed: passed,
      message: message
    }
  end
end

# Chạy test nếu file được gọi trực tiếp
if __FILE__ == $0
  FacebookTypingTest.new.run_all_tests
end
