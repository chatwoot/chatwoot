import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { JSDOM } from 'jsdom';
import {
  InitializationHelpers,
  openExternalLinksInNewTab,
} from '../portalHelpers';

describe('InitializationHelpers.navigateToLocalePage', () => {
  let dom;
  let document;
  let window;

  beforeEach(() => {
    dom = new JSDOM(
      '<!DOCTYPE html><html><body><div class="locale-switcher" data-portal-slug="test-slug"><select><option value="en">English</option><option value="fr">French</option></select></div></body></html>',
      { url: 'http://localhost/' }
    );
    document = dom.window.document;
    window = dom.window;
    global.document = document;
    global.window = window;
  });

  afterEach(() => {
    dom = null;
    document = null;
    window = null;
    delete global.document;
    delete global.window;
  });

  it('should return false if .locale-switcher is not found', () => {
    document.querySelector('.locale-switcher').remove();
    const result = InitializationHelpers.navigateToLocalePage();
    expect(result).toBe(false);
  });

  it('should add change event listener to .locale-switcher', () => {
    const localeSwitcher = document.querySelector('.locale-switcher');
    const addEventListenerSpy = vi.spyOn(localeSwitcher, 'addEventListener');

    InitializationHelpers.navigateToLocalePage();

    expect(addEventListenerSpy).toHaveBeenCalledWith(
      'change',
      expect.any(Function)
    );
  });
});

describe('openExternalLinksInNewTab', () => {
  let dom;
  let document;
  let window;

  beforeEach(() => {
    dom = new JSDOM(
      `<!DOCTYPE html>
      <html>
        <body>
          <div id="cw-article-content">
            <a href="https://external.com" id="external">External</a>
            <a href="https://app.chatwoot.com/page" id="internal">Internal</a>
            <a href="https://custom.domain.com/page" id="custom">Custom</a>
            <a href="https://example.com" id="nested"><code>Code</code><strong>Bold</strong></a>
            <ul>
              <li>Visit the preferences centre here &gt; <a href="https://external.com" id="list-link"><strong>https://external.com</strong></a></li>
            </ul>
          </div>
        </body>
      </html>`,
      { url: 'https://app.chatwoot.com/hc/article' }
    );

    document = dom.window.document;
    window = dom.window;

    window.portalConfig = {
      customDomain: 'custom.domain.com',
      hostURL: 'app.chatwoot.com',
    };

    global.document = document;
    global.window = window;
  });

  afterEach(() => {
    dom = null;
    document = null;
    window = null;
    delete global.document;
    delete global.window;
  });

  const simulateClick = selector => {
    const element = document.querySelector(selector);
    const event = new window.MouseEvent('click', { bubbles: true });
    element.dispatchEvent(event);
    return element.closest('a') || element;
  };

  it('opens external links in new tab', () => {
    openExternalLinksInNewTab();

    const link = simulateClick('#external');
    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');
  });

  it('preserves internal links', () => {
    openExternalLinksInNewTab();

    const internal = simulateClick('#internal');
    const custom = simulateClick('#custom');

    expect(internal.target).not.toBe('_blank');
    expect(custom.target).not.toBe('_blank');
  });

  it('handles clicks on nested elements', () => {
    openExternalLinksInNewTab();

    simulateClick('#nested code');
    simulateClick('#nested strong');

    const link = document.getElementById('nested');
    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');
  });

  it('handles links inside list items with strong tags', () => {
    openExternalLinksInNewTab();

    // Click on the strong element inside the link in the list
    simulateClick('#list-link strong');

    const link = document.getElementById('list-link');
    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');
  });

  it('opens external links in a new tab even if customDomain is empty', () => {
    window = dom.window;
    window.portalConfig = {
      hostURL: 'app.chatwoot.com',
    };

    global.window = window;

    openExternalLinksInNewTab();

    const link = simulateClick('#external');
    const internal = simulateClick('#internal');
    const custom = simulateClick('#custom');

    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');

    expect(internal.target).not.toBe('_blank');
    // this will be blank since the configs customDomain is empty
    // which is a fair expectation
    expect(custom.target).toBe('_blank');
  });

  it('opens external links in a new tab even if hostURL is empty', () => {
    window = dom.window;
    window.portalConfig = {
      customDomain: 'custom.domain.com',
    };

    global.window = window;

    openExternalLinksInNewTab();

    const link = simulateClick('#external');
    const internal = simulateClick('#internal');
    const custom = simulateClick('#custom');

    expect(link.target).toBe('_blank');
    expect(link.rel).toBe('noopener noreferrer');

    expect(internal.target).not.toBe('_blank');
    expect(custom.target).not.toBe('_blank');
  });
});
