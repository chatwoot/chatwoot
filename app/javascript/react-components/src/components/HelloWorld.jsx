import React, { useState } from 'react';

export const HelloWorld = () => {
  const [count, setCount] = useState(0);

  return (
    <div style={{ 
      padding: '20px', 
      border: '1px solid #ccc', 
      borderRadius: '8px',
      fontFamily: 'Arial, sans-serif',
      maxWidth: '300px',
      margin: '20px auto',
      textAlign: 'center'
    }}>
      <h2>Hello from Chatwoot React!</h2>
      <p>Count: {count}</p>
      <button 
        onClick={() => setCount(count + 1)}
        style={{
          padding: '10px 20px',
          backgroundColor: '#007bff',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer',
          fontSize: '16px'
        }}
      >
        Increment
      </button>
      <button 
        onClick={() => setCount(0)}
        style={{
          padding: '10px 20px',
          backgroundColor: '#dc3545',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer',
          fontSize: '16px',
          marginLeft: '10px'
        }}
      >
        Reset
      </button>
    </div>
  );
};