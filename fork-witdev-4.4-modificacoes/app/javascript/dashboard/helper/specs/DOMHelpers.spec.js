import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { loadScript } from '../DOMHelpers';
import { JSDOM } from 'jsdom';

describe('loadScript', () => {
  let dom;
  let window;
  let document;

  beforeEach(() => {
    dom = new JSDOM('<!DOCTYPE html><html><head></head><body></body></html>', {
      url: 'http://localhost',
    });
    window = dom.window;
    document = window.document;
    global.document = document;
  });

  afterEach(() => {
    vi.restoreAllMocks();
    delete global.document;
  });

  it('should load a script successfully', async () => {
    const src = 'https://example.com/script.js';
    const loadPromise = loadScript(src, {});

    // Simulate successful script load
    setTimeout(() => {
      const script = document.querySelector(`script[src="${src}"]`);
      if (script) {
        script.dispatchEvent(new window.Event('load'));
      }
    }, 0);

    const script = await loadPromise;

    expect(script).toBeTruthy();
    expect(script.getAttribute('src')).toBe(src);
    expect(script.getAttribute('data-loaded')).toBe('true');
  });

  it('should not load a script if document is not available', async () => {
    delete global.document;
    const result = await loadScript('https://example.com/script.js', {});
    expect(result).toBe(false);
  });

  it('should use an existing script if already present', async () => {
    const src = 'https://example.com/existing-script.js';
    const existingScript = document.createElement('script');
    existingScript.src = src;
    existingScript.setAttribute('data-loaded', 'true');
    document.head.appendChild(existingScript);

    const script = await loadScript(src, {});

    expect(script).toBe(existingScript);
  });

  it('should set custom attributes on the script element', async () => {
    const src = 'https://example.com/custom-script.js';
    const options = {
      type: 'module',
      async: false,
      defer: true,
      crossOrigin: 'anonymous',
      noModule: true,
      referrerPolicy: 'origin',
      id: 'custom-script',
      attrs: { 'data-custom': 'value' },
    };

    const loadPromise = loadScript(src, options);

    // Simulate successful script load
    setTimeout(() => {
      const script = document.querySelector(`script[src="${src}"]`);
      if (script) {
        script.dispatchEvent(new window.Event('load'));
      }
    }, 0);

    const script = await loadPromise;

    expect(script.type).toBe('module');
    expect(script.async).toBe(false);
    expect(script.defer).toBe(true);
    expect(script.crossOrigin).toBe('anonymous');
    expect(script.noModule).toBe(true);
    expect(script.referrerPolicy).toBe('origin');
    expect(script.id).toBe('custom-script');
    expect(script.getAttribute('data-custom')).toBe('value');
  });
});
