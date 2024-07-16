class ScriptLoaderError extends Error {
  constructor(message, src) {
    super(message);
    this.name = 'ScriptLoaderError';
    this.src = src;
  }

  getErrorDetails() {
    return `Failed to load script from source: ${this.src}`;
  }
}

// Helper function to create a new script element
const createScriptElement = (src, options) => {
  const el = document.createElement('script');
  el.type = options.type || 'text/javascript';
  el.async = options.async !== false;
  el.src = src;

  if (options.defer) el.defer = options.defer;
  if (options.crossOrigin) el.crossOrigin = options.crossOrigin;
  if (options.noModule) el.noModule = options.noModule;
  if (options.referrerPolicy) el.referrerPolicy = options.referrerPolicy;
  if (options.id) el.id = options.id;

  Object.entries(options.attrs || {}).forEach(([name, value]) =>
    el.setAttribute(name, value)
  );

  return el;
};

// Helper function to find an existing script element
const findExistingScript = src => {
  return document.querySelector(`script[src="${src}"]`);
};

// Main loadScript function
export async function loadScript(src, options) {
  return new Promise((resolve, reject) => {
    if (typeof window === 'undefined' || !window.document) {
      resolve(false);
      return;
    }

    let el = findExistingScript(src);

    if (!el) {
      el = createScriptElement(src, options);
      document.head.appendChild(el);
    } else if (el.hasAttribute('data-loaded')) {
      resolve(el);
      return;
    }

    const scriptLoaderError = new ScriptLoaderError(
      `Failed to load script`,
      src
    );

    el.addEventListener('error', () => reject(scriptLoaderError));
    el.addEventListener('abort', () => reject(scriptLoaderError));
    el.addEventListener('load', () => {
      el.setAttribute('data-loaded', 'true');
      resolve(el);
    });
  });
}
