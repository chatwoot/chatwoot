const axios = require('axios');

// Cấu hình API - Thay đổi theo môi trường của bạn
const CONFIG = {
  API_BASE: 'https://your-chatwoot-domain.com/api/v1',
  ACCOUNT_ID: 'your-account-id',
  BOT_ACCESS_TOKEN: 'your-bot-access-token'
};

/**
 * Test cấu hình human_agent cho conversation
 */
async function testHumanAgent(conversationId) {
  try {
    console.log(`🧪 Testing human agent configuration for conversation ${conversationId}...`);
    
    const response = await axios.post(
      `${CONFIG.API_BASE}/accounts/${CONFIG.ACCOUNT_ID}/conversations/${conversationId}/test_human_agent`,
      {},
      {
        headers: {
          'api_access_token': CONFIG.BOT_ACCESS_TOKEN,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log(`✅ Human agent test completed for conversation ${conversationId}`);
    console.log('📊 Test Results:');
    console.log('================');
    
    const results = response.data.results;
    
    // Hiển thị kết quả global config
    if (results.global_config) {
      console.log('\n🔧 Global Configuration:');
      console.log(`  Facebook Messenger Human Agent: ${results.global_config.facebook_messenger?.enabled ? '✅ ENABLED' : '❌ DISABLED'}`);
      console.log(`  Instagram Human Agent: ${results.global_config.instagram?.enabled ? '✅ ENABLED' : '❌ DISABLED'}`);
      console.log(`  Current Channel: ${results.global_config.current_channel}`);
      console.log(`  Current Channel Human Agent: ${results.global_config.current_channel_enabled ? '✅ ENABLED' : '❌ DISABLED'}`);
    }
    
    // Hiển thị kết quả test message
    if (results.message_test) {
      console.log('\n📨 Message Test:');
      console.log(`  Success: ${results.message_test.success ? '✅' : '❌'}`);
      console.log(`  Messaging Type: ${results.message_test.messaging_type}`);
      console.log(`  Tag: ${results.message_test.tag}`);
      console.log(`  Human Agent Detected: ${results.message_test.human_agent_detected ? '✅ YES' : '❌ NO'}`);
      
      if (results.message_test.error) {
        console.log(`  Error: ${results.message_test.error}`);
      }
    }
    
    // Hiển thị kết quả permissions
    if (results.permissions) {
      console.log('\n🔐 Facebook Permissions:');
      console.log(`  Success: ${results.permissions.success ? '✅' : '❌'}`);
      console.log(`  Has pages_messaging: ${results.permissions.has_pages_messaging ? '✅ YES' : '❌ NO'}`);
      console.log(`  Permission Status: ${results.permissions.permission_status || 'N/A'}`);
      
      if (results.permissions.all_permissions) {
        console.log('  All Permissions:');
        results.permissions.all_permissions.forEach(perm => {
          console.log(`    - ${perm}`);
        });
      }
      
      if (results.permissions.error) {
        console.log(`  Error: ${results.permissions.error}`);
      }
    }
    
    // Đưa ra khuyến nghị
    console.log('\n💡 Recommendations:');
    if (results.global_config?.current_channel_enabled) {
      console.log('  ✅ Human agent is properly configured for this channel');
      console.log('  ✅ Messages should bypass 24-hour window restriction');
    } else {
      console.log('  ❌ Human agent is NOT enabled for this channel');
      console.log('  ❌ Messages will be subject to 24-hour window restriction');
      console.log('  💡 Enable human agent in Super Admin settings to fix this');
    }
    
    if (results.permissions && !results.permissions.has_pages_messaging) {
      console.log('  ⚠️  Missing pages_messaging permission');
      console.log('  💡 Request additional permissions from Facebook for your app');
    }
    
    return response.data;
  } catch (error) {
    console.error(`❌ Error testing human agent:`, error.response?.data || error.message);
    return false;
  }
}

/**
 * Gửi tin nhắn test để kiểm tra human_agent hoạt động
 */
async function sendTestMessage(conversationId, content = 'Test message with human agent - should bypass 24h window') {
  try {
    console.log(`📤 Sending test message to conversation ${conversationId}...`);
    
    const response = await axios.post(
      `${CONFIG.API_BASE}/accounts/${CONFIG.ACCOUNT_ID}/conversations/${conversationId}/messages`,
      {
        content: content,
        message_type: 'outgoing'
      },
      {
        headers: {
          'api_access_token': CONFIG.BOT_ACCESS_TOKEN,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log(`✅ Test message sent successfully`);
    console.log(`📨 Message ID: ${response.data.id}`);
    return response.data;
  } catch (error) {
    console.error(`❌ Error sending test message:`, error.response?.data || error.message);
    
    // Kiểm tra lỗi 24h window
    if (error.response?.data?.message?.includes('24') || error.response?.data?.message?.includes('window')) {
      console.log('🚨 This appears to be a 24-hour window restriction error!');
      console.log('💡 Human agent may not be properly configured or approved by Facebook');
    }
    
    return false;
  }
}

/**
 * Chạy test đầy đủ cho human agent
 */
async function runFullHumanAgentTest(conversationId) {
  console.log('🚀 Starting comprehensive human agent test...\n');
  
  // Bước 1: Test cấu hình
  console.log('Step 1: Testing configuration...');
  const configTest = await testHumanAgent(conversationId);
  
  if (!configTest) {
    console.log('❌ Configuration test failed. Stopping here.');
    return;
  }
  
  // Bước 2: Test gửi tin nhắn
  console.log('\nStep 2: Testing message sending...');
  const messageTest = await sendTestMessage(conversationId);
  
  // Tổng kết
  console.log('\n🏁 Test Summary:');
  console.log('================');
  
  const humanAgentEnabled = configTest.results?.global_config?.current_channel_enabled;
  const messageSent = !!messageTest;
  
  if (humanAgentEnabled && messageSent) {
    console.log('🎉 SUCCESS: Human agent is working correctly!');
    console.log('✅ Configuration is correct');
    console.log('✅ Messages can bypass 24-hour window');
  } else if (humanAgentEnabled && !messageSent) {
    console.log('⚠️  PARTIAL: Configuration looks good but message failed');
    console.log('💡 Check Facebook app permissions and approval status');
  } else if (!humanAgentEnabled) {
    console.log('❌ FAILED: Human agent is not properly configured');
    console.log('💡 Enable human agent in Super Admin settings');
  }
}

// Export functions để có thể sử dụng từ file khác
module.exports = {
  testHumanAgent,
  sendTestMessage,
  runFullHumanAgentTest,
  CONFIG
};

// Nếu chạy trực tiếp từ command line
if (require.main === module) {
  const conversationId = process.argv[2];
  
  if (!conversationId) {
    console.log('Usage: node human_agent_demo.js <conversation_id>');
    console.log('Example: node human_agent_demo.js 123');
    process.exit(1);
  }
  
  runFullHumanAgentTest(conversationId)
    .then(() => {
      console.log('\n✅ Test completed');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Test failed:', error.message);
      process.exit(1);
    });
}
