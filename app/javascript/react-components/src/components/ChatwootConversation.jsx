import { useState, useCallback } from 'react';
import { useChatwoot } from './ChatwootProvider';
import { ChatwootMessageListWrapper } from './ChatwootMessageListWrapper';

export const ChatwootConversation = ({
  conversationId,
  className = '',
  style = {},
  onError = null,
  onLoad = null,
  ...otherProps
}) => {
  // Ensure we're inside a ChatwootProvider
  useChatwoot(); // This will throw if not in Provider context

  const [, setIsLoaded] = useState(false);
  const [, setError] = useState(null);

  // Validate required props
  if (!conversationId) {
    throw new Error('ChatwootConversation: conversationId is required');
  }

  const handleLoad = useCallback(() => {
    setIsLoaded(true);
    setError(null);
    onLoad?.();
  }, [onLoad]);

  const handleError = useCallback(
    err => {
      setError(err.message);
      setIsLoaded(false);
      onError?.(err);
    },
    [onError]
  );

  return (
    <div
      className={`chatwoot-conversation ${className}`}
      style={{
        height: '100%',
        width: '100%',
        position: 'relative',
        ...style,
      }}
    >
      <ChatwootMessageListWrapper
        conversationId={conversationId}
        onLoad={handleLoad}
        onError={handleError}
        className="h-full w-full"
        {...otherProps}
      />
    </div>
  );
};

// Export props interface for TypeScript users (future)
// export interface ChatwootConversationProps {
//   conversationId: number | string;
//   className?: string;
//   style?: React.CSSProperties;
//   onError?: (error: Error) => void;
//   onLoad?: () => void;
// }
