export function loadIntercom({ shopUrl }) {
  try {
    // Set Intercom settings
    window.intercomSettings = {
      api_base: 'https://api-iam.intercom.io',
      app_id: 'sx8k4u4v',
      user_id: shopUrl,
      name: shopUrl,
      company: {
        company_id: shopUrl,
        name: shopUrl,
      },
    };

    // Initialize Intercom if not already initialized
    if (typeof window.Intercom === 'function') {
      window.Intercom('update', window.intercomSettings);
    } else {
      // Load Intercom script
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.async = true;
      script.src = `https://widget.intercom.io/widget/sx8k4u4v`;
      const firstScript = document.getElementsByTagName('script')[0];
      firstScript.parentNode.insertBefore(script, firstScript);
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error initializing Intercom:', error);
  }
}

export function shutdownIntercom() {
  if (typeof window.Intercom === 'function') {
    window.Intercom('shutdown');
  }
}

// Helper function to show/hide messenger
export function showIntercomMessenger() {
  if (typeof window.Intercom === 'function') {
    window.Intercom('show');
  }
}

export function hideIntercomMessenger() {
  if (typeof window.Intercom === 'function') {
    window.Intercom('hide');
  }
}
