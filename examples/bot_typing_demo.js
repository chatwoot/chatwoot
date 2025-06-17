/**
 * Bot Agent Typing Demo
 * 
 * Ví dụ về cách sử dụng API toggle_typing_status để tạo trải nghiệm tốt nhất
 * cho người dùng khi bot đang "suy nghĩ" để tạo câu trả lời.
 */

const axios = require('axios');

// Cấu hình
const CONFIG = {
  API_BASE: 'https://app.mooly.vn/api/v1',
  ACCOUNT_ID: '220', // Thay bằng account ID thực tế
  BOT_ACCESS_TOKEN: 'your_bot_access_token_here', // Thay bằng bot access token thực tế
  AI_SERVICE_URL: 'https://your-ai-service.com/chat' // URL của AI service
};

/**
 * Gửi typing indicator
 */
async function toggleTyping(conversationId, status) {
  try {
    const response = await axios.post(
      `${CONFIG.API_BASE}/accounts/${CONFIG.ACCOUNT_ID}/conversations/${conversationId}/toggle_typing_status`,
      {
        typing_status: status,
        is_private: false
      },
      {
        headers: {
          'api_access_token': CONFIG.BOT_ACCESS_TOKEN,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log(`✅ Typing ${status.toUpperCase()} sent successfully for conversation ${conversationId}`);
    return true;
  } catch (error) {
    console.error(`❌ Error sending typing ${status}:`, error.response?.data || error.message);
    return false;
  }
}

/**
 * Gửi tin nhắn
 */
async function sendMessage(conversationId, content) {
  try {
    const response = await axios.post(
      `${CONFIG.API_BASE}/accounts/${CONFIG.ACCOUNT_ID}/conversations/${conversationId}/messages`,
      {
        content: content,
        message_type: 'outgoing',
        private: false
      },
      {
        headers: {
          'api_access_token': CONFIG.BOT_ACCESS_TOKEN,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log(`✅ Message sent successfully: "${content}"`);
    return response.data;
  } catch (error) {
    console.error('❌ Error sending message:', error.response?.data || error.message);
    return null;
  }
}

/**
 * Mô phỏng gọi AI service
 */
async function callAIService(userMessage) {
  console.log(`🤖 Calling AI service for: "${userMessage}"`);
  
  // Mô phỏng thời gian xử lý AI (2-5 giây)
  const processingTime = Math.random() * 3000 + 2000;
  await new Promise(resolve => setTimeout(resolve, processingTime));
  
  // Mô phỏng response từ AI
  const responses = [
    "Tôi hiểu câu hỏi của bạn. Đây là câu trả lời chi tiết...",
    "Cảm ơn bạn đã hỏi! Theo tôi được biết thì...",
    "Đây là một câu hỏi thú vị. Hãy để tôi giải thích...",
    "Tôi sẽ giúp bạn giải quyết vấn đề này..."
  ];
  
  return responses[Math.floor(Math.random() * responses.length)];
}

/**
 * Xử lý tin nhắn từ user với typing indicators
 */
async function handleUserMessage(conversationId, userMessage) {
  console.log(`\n📨 Received message: "${userMessage}" in conversation ${conversationId}`);
  
  try {
    // Bước 1: Bật typing indicator ngay lập tức
    console.log('⌨️  Enabling typing indicator...');
    await toggleTyping(conversationId, 'on');
    
    // Bước 2: Gọi AI service (mất thời gian)
    const aiResponse = await callAIService(userMessage);
    
    // Bước 3: Tắt typing indicator
    console.log('⌨️  Disabling typing indicator...');
    await toggleTyping(conversationId, 'off');
    
    // Bước 4: Gửi tin nhắn cho user
    await sendMessage(conversationId, aiResponse);
    
    console.log('✅ Message handling completed successfully!\n');
    
  } catch (error) {
    console.error('❌ Error handling message:', error);
    
    // Đảm bảo tắt typing indicator nếu có lỗi
    console.log('🔧 Cleaning up: disabling typing indicator...');
    await toggleTyping(conversationId, 'off');
  }
}

/**
 * Demo với nhiều tin nhắn
 */
async function runDemo() {
  console.log('🚀 Starting Bot Typing Demo...\n');
  
  const conversationId = '123'; // Thay bằng conversation ID thực tế
  
  const testMessages = [
    'Xin chào, bạn có thể giúp tôi không?',
    'Tôi muốn biết thông tin về sản phẩm',
    'Làm thế nào để đặt hàng?',
    'Cảm ơn bạn đã hỗ trợ!'
  ];
  
  for (const message of testMessages) {
    await handleUserMessage(conversationId, message);
    
    // Chờ một chút giữa các tin nhắn
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log('🎉 Demo completed!');
}

/**
 * Test typing functionality
 */
async function testTyping() {
  console.log('🧪 Testing typing functionality...\n');
  
  const conversationId = '123'; // Thay bằng conversation ID thực tế
  
  // Test bật typing
  console.log('Testing typing ON...');
  await toggleTyping(conversationId, 'on');
  
  // Chờ 3 giây
  console.log('Waiting 3 seconds...');
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Test tắt typing
  console.log('Testing typing OFF...');
  await toggleTyping(conversationId, 'off');
  
  console.log('✅ Typing test completed!');
}

// Export functions để có thể sử dụng trong các file khác
module.exports = {
  toggleTyping,
  sendMessage,
  handleUserMessage,
  runDemo,
  testTyping
};

// Chạy demo nếu file được execute trực tiếp
if (require.main === module) {
  const command = process.argv[2];
  
  switch (command) {
    case 'demo':
      runDemo();
      break;
    case 'test':
      testTyping();
      break;
    default:
      console.log('Usage:');
      console.log('  node bot_typing_demo.js demo  - Run full demo');
      console.log('  node bot_typing_demo.js test  - Test typing only');
  }
}
