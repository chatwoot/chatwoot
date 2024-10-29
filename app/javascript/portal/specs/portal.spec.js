import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { JSDOM } from 'jsdom';
import { InitializationHelpers } from '../portalHelpers';

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
