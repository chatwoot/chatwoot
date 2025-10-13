// Apple Messages Rich Link Helper
// Automatic URL detection and Rich Link conversion for Apple Messages conversations

// Enhanced URL regex that detects URLs with and without protocol
export const URL_REGEX =
  /(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s<>"{}|\\^`[\]]*)?/gi;

export const isAppleMessagesConversation = conversation => {
  return (
    conversation?.inbox?.channel_type === 'Channel::AppleMessagesForBusiness'
  );
};

// Normalize URL by adding protocol if missing
export const normalizeURL = url => {
  if (!url || typeof url !== 'string') return url;

  // Already has protocol
  if (url.match(/^https?:\/\//)) return url;

  // Add https:// protocol for www. and domain.tld patterns
  if (url.match(/^(www\.|[a-zA-Z0-9-]+\.[a-zA-Z]{2,})/)) {
    return `https://${url}`;
  }

  return url;
};

export const detectURLsInText = text => {
  if (!text || typeof text !== 'string') return [];

  const urls = text.match(URL_REGEX);
  // Normalize URLs by adding protocol if missing
  return urls ? [...new Set(urls.map(normalizeURL))] : [];
};

export const shouldAutoConvertToRichLink = conversation => {
  // Always auto-convert URLs for Apple Messages conversations
  return isAppleMessagesConversation(conversation);
};

// Split message into parts: text before URL, URL, text after URL
export const splitMessageByURLs = text => {
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

    // Add URL as Rich Link (normalize URL first)
    parts.push({ type: 'url', content: normalizeURL(match[0]) });

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

export const extractMainURL = text => {
  const urls = detectURLsInText(text);
  return urls.length > 0 ? urls[0] : null;
};

export const createRichLinkPreview = async url => {
  try {
    // Normalize URL before sending to backend
    const normalizedURL = normalizeURL(url);

    // Get account ID from current URL path
    const accountId = window.location.pathname.match(/accounts\/(\d+)/)?.[1];
    if (!accountId) {
      throw new Error('Account ID not found');
    }

    // Call backend to parse OpenGraph data
    const response = await fetch(
      `/api/v1/accounts/${accountId}/apple_messages/parse_url`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'same-origin', // Include cookies for authentication
        body: JSON.stringify({ url: normalizedURL }),
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    return {
      success: true,
      richLinkData: {
        url: data.url,
        title: data.title,
        description: data.description,
        image_url: data.image_url,
        favicon_url: data.favicon_url,
        image_data: data.image_url, // For backward compatibility
        image_mime_type: 'image/jpeg',
        site_name: data.site_name,
      },
    };
  } catch (error) {
    console.error('Rich Link preview failed:', error);
    return {
      success: false,
      error: error.message,
      // Fallback data
      richLinkData: {
        url,
        title: extractDomainFromURL(url),
        description: null,
        image_url: null,
        site_name: extractDomainFromURL(url),
      },
    };
  }
};

export const extractDomainFromURL = url => {
  try {
    const urlObj = new URL(url);
    return urlObj.hostname.replace('www.', '');
  } catch {
    return 'Website';
  }
};

export const formatRichLinkMessage = (richLinkData, originalText) => {
  return {
    content: originalText,
    content_type: 'apple_rich_link',
    content_attributes: {
      url: richLinkData.url,
      title: richLinkData.title,
      description: richLinkData.description,
      image_url: richLinkData.image_url,
      favicon_url: richLinkData.favicon_url,
      site_name: richLinkData.site_name,
    },
  };
};

// Debounced URL detection for real-time preview
export const createDebouncedURLDetector = (callback, delay = 500) => {
  let timeoutId;

  return (text, conversation) => {
    clearTimeout(timeoutId);

    timeoutId = setTimeout(() => {
      if (shouldAutoConvertToRichLink(conversation, text)) {
        const url = extractMainURL(text);
        if (url) {
          callback(url, text);
        }
      }
    }, delay);
  };
};

// Rich Link suggestion for agents
export const createRichLinkSuggestion = (url, richLinkData) => {
  return {
    type: 'rich_link_suggestion',
    url,
    title: richLinkData.title,
    description: richLinkData.description,
    image_url: richLinkData.image_url,
    action: 'convert_to_rich_link',
  };
};

// Process message content and create multiple messages for Apple Messages
export const processMessageForAppleMessages = async (
  messageContent,
  conversation
) => {
  if (!isAppleMessagesConversation(conversation)) {
    return [{ type: 'text', content: messageContent }];
  }

  const parts = splitMessageByURLs(messageContent);

  // ✅ NEW APPROACH: If message contains URLs, create a single rich link with full text
  // This avoids Apple's message ordering issues entirely
  const hasUrls = parts.some(part => part.type === 'url');

  if (hasUrls) {
    // Find the first URL for rich link generation
    const urlPart = parts.find(part => part.type === 'url');

    if (urlPart) {
      // Convert URL to Rich Link with full message text
      const richLinkPreview = await createRichLinkPreview(urlPart.content);

      if (richLinkPreview.success) {
        return [
          {
            type: 'rich_link',
            content: messageContent, // Use full original message as content
            content_type: 'apple_rich_link',
            content_attributes: {
              ...richLinkPreview.richLinkData,
              // Add the full message text as title or description if not present
              title: richLinkPreview.richLinkData.title || messageContent,
              description:
                richLinkPreview.richLinkData.description ||
                `${messageContent}\n\n${richLinkPreview.richLinkData.url}`,
            },
          },
        ];
      }
    }
  }

  // Fallback: Process as separate messages (original behavior)
  const processedMessages = [];

  for (const part of parts) {
    if (part.type === 'text') {
      processedMessages.push({
        type: 'text',
        content: part.content,
        content_type: 'text',
        content_attributes: {},
      });
    } else if (part.type === 'url') {
      // Convert URL to Rich Link
      const richLinkPreview = await createRichLinkPreview(part.content);

      if (richLinkPreview.success) {
        processedMessages.push({
          type: 'rich_link',
          content: part.content, // Original URL as fallback
          content_type: 'apple_rich_link',
          content_attributes: richLinkPreview.richLinkData,
        });
      } else {
        // Fallback to text if Rich Link fails
        processedMessages.push({
          type: 'text',
          content: part.content,
          content_type: 'text',
          content_attributes: {},
        });
      }
    }
  }

  return processedMessages;
};

// Process canned response for automatic Rich Link conversion
export const processCannedResponseForAppleMessages = async (
  cannedResponseContent,
  conversation
) => {
  return processMessageForAppleMessages(cannedResponseContent, conversation);
};

// Apple Messages specific URL patterns that work well as Rich Links
export const APPLE_FRIENDLY_DOMAINS = [
  'apple.com',
  'apps.apple.com',
  'support.apple.com',
  'developer.apple.com',
  'youtube.com',
  'youtu.be',
  'github.com',
  'twitter.com',
  'x.com',
  'instagram.com',
  'facebook.com',
  'linkedin.com',
  'medium.com',
  'news.ycombinator.com',
  'reddit.com',
];

export const isAppleFriendlyURL = url => {
  try {
    const urlObj = new URL(url);
    const domain = urlObj.hostname.replace('www.', '');
    return APPLE_FRIENDLY_DOMAINS.some(
      friendlyDomain =>
        domain === friendlyDomain || domain.endsWith(`.${friendlyDomain}`)
    );
  } catch {
    return false;
  }
};

export const getRichLinkRecommendation = url => {
  if (isAppleFriendlyURL(url)) {
    return {
      recommended: true,
      reason: 'This URL is known to work well with Apple Messages Rich Links',
      confidence: 'high',
    };
  }

  return {
    recommended: true,
    reason: 'Rich Links provide better user experience than plain URLs',
    confidence: 'medium',
  };
};
