import React, { useEffect, useRef, useState } from 'react';
import { registerVueWebComponents } from '../vue-components/registerWebComponents';

export const VueWebComponentWrapper = ({
  initialCount = 0,
  title = 'Hello from Vue in React!',
  color = '#42b883',
  ...otherProps
}) => {
  const elementRef = useRef();
  const [isReady, setIsReady] = useState(false);
  const [currentCount, setCurrentCount] = useState(initialCount);

  // Register Web Components on mount
  useEffect(() => {
    registerVueWebComponents();
    setIsReady(true);

    // Listen for custom events from Vue component
    const handleCountChange = event => {
      setCurrentCount(event.detail.count);
      console.log('Vue component count changed:', event.detail.count);
    };

    document.addEventListener('vue-counter-changed', handleCountChange);

    return () => {
      document.removeEventListener('vue-counter-changed', handleCountChange);
    };
  }, []);

  // Update Web Component properties when React props change
  useEffect(() => {
    if (!isReady || !elementRef.current) return;

    const element = elementRef.current;

    // Set properties on the Web Component
    // Vue converts camelCase props to kebab-case attributes
    element.setAttribute('initial-count', initialCount);
    element.setAttribute('title', title);
    element.setAttribute('color', color);

    console.log('Updated Vue Web Component props:', {
      initialCount,
      title,
      color,
    });
  }, [isReady, initialCount, title, color]);

  if (!isReady) {
    return (
      <div
        style={{
          padding: '20px',
          textAlign: 'center',
          border: '1px dashed #ccc',
          borderRadius: '8px',
          color: '#666',
        }}
      >
        Loading Vue Web Component...
      </div>
    );
  }

  return (
    <div style={{ margin: '20px 0' }}>
      <div
        style={{
          padding: '10px',
          backgroundColor: '#f8f9fa',
          borderRadius: '4px',
          marginBottom: '10px',
          fontSize: '14px',
          color: '#666',
        }}
      >
        <strong>React Wrapper Info:</strong> Current count tracked by React:{' '}
        {currentCount}
      </div>

      {/* This is the Vue Web Component rendered inside React */}
      <vue-hello-world
        ref={elementRef}
        initial-count={initialCount}
        title={title}
        color={color}
        {...otherProps}
      />

      <div
        style={{
          padding: '10px',
          backgroundColor: '#e8f5e8',
          borderRadius: '4px',
          marginTop: '10px',
          fontSize: '12px',
          color: '#666',
        }}
      >
        ✅ This Vue component is running as a Web Component inside React!
      </div>
    </div>
  );
};
