// Test Apple Messages URL splitting logic
// Run with: node test_url_splitting.js

const URL_REGEX = /(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s<>"{}|\\^`[\]]*)?/gi;

const splitMessageByURLs = (text) => {
  if (!text || typeof text !== 'string')
    return [{ type: 'text', content: text }];

  const parts = [];
  let lastIndex = 0;
  let match;

  // Reset regex to start from beginning
  const urlRegex = new RegExp(URL_REGEX.source, URL_REGEX.flags);

  while ((match = urlRegex.exec(text)) !== null) {
    // Add text before URL if exists
    if (match.index > lastIndex) {
      const beforeText = text.slice(lastIndex, match.index).trim();
      if (beforeText) {
        parts.push({ type: 'text', content: beforeText });
      }
    }

    // Add URL as Rich Link
    parts.push({ type: 'url', content: match[0] });

    lastIndex = match.index + match[0].length;
  }

  // Add remaining text after last URL if exists
  if (lastIndex < text.length) {
    const afterText = text.slice(lastIndex).trim();
    if (afterText) {
      parts.push({ type: 'text', content: afterText });
    }
  }

  // If no URLs found, return original text
  if (parts.length === 0) {
    parts.push({ type: 'text', content: text });
  }

  return parts;
};

// Test cases
const testCases = [
  "best one https://www.ysl.com/fr-fr/pr/joe-cuissardes-en-cuir-lisse-843714AAE901000.html to choose from",
  "Check out https://github.com/chatwoot/chatwoot for code",
  "https://apple.com is amazing",
  "Multiple sites: https://example.com and https://test.com work great!",
  "No URLs here",
];

console.log('🔗 Testing Apple Messages URL Splitting Logic');
console.log('===============================================');

testCases.forEach((message, index) => {
  console.log(`\n${index + 1}. Testing: "${message}"`);
  
  const parts = splitMessageByURLs(message);
  console.log(`   📝 Split into ${parts.length} parts:`);
  
  parts.forEach((part, i) => {
    console.log(`      ${i + 1}. [${part.type.toUpperCase()}] "${part.content}"`);
  });
  
  console.log(`   💬 Would send: ${parts.length} separate message(s)`);
});

console.log('\n✅ URL splitting logic test complete!');