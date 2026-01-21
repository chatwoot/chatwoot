import { useRef, useEffect } from 'react';

export const ChatwootMessageListWrapper = ({
  conversationId,
  className = '',
  style = {},
  onError = null,
  onLoad = null,
  ...otherProps
}) => {
  const elementRef = useRef();

  // Update Web Component props when React props change
  useEffect(() => {
    if (!elementRef.current) return;

    const element = elementRef.current;

    // Set conversation ID on the Web Component
    element.conversationId = conversationId;

  }, [conversationId]);

  // Handle Web Component events
  useEffect(() => {
    if (!elementRef.current) return;

    const element = elementRef.current;

    const handleLoad = () => {
      onLoad?.();
    };

    const handleError = (event) => {
      const errorMessage = event.detail?.message || 'Unknown error occurred';
      onError?.(new Error(errorMessage));
    };

    // Listen for custom events from the Web Component
    element.addEventListener('chatwoot:loaded', handleLoad);
    element.addEventListener('chatwoot:error', handleError);

    return () => {
      element.removeEventListener('chatwoot:loaded', handleLoad);
      element.removeEventListener('chatwoot:error', handleError);
    };
  }, [onLoad, onError]);

  // Render the Web Component
  // Global setup is handled by ChatwootProvider
  return (
    <chatwoot-message-list
      ref={elementRef}
      className={className}
      style={style}
      {...otherProps}
    />
  );
};
