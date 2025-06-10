import { useChatwoot } from './ChatwootProvider';
import { ChatwootMessageListWrapper } from './ChatwootMessageListWrapper';

export const ChatwootConversation = ({
  conversationId,
  className = '',
  style = {},
  ...otherProps
}) => {
  // Ensure we're inside a ChatwootProvider
  useChatwoot(); // This will throw if not in Provider context

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
      <ChatwootMessageListWrapper className="h-full w-full" {...otherProps} />
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
