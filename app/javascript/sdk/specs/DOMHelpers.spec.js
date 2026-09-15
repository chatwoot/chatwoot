import { normalizePageContext, onLocationChangeListener } from '../DOMHelpers';
import { IFrameHelper } from '../IFrameHelper';

vi.mock('../IFrameHelper', () => ({
  IFrameHelper: {
    events: {
      onLocationChange: vi.fn(),
    },
  },
}));

describe('#normalizePageContext', () => {
  it('accepts HTTP(S) URLs and bounds route metadata', () => {
    const context = normalizePageContext({
      url: 'https://example.com/docs?utm_source=chat#install',
      title: 'A'.repeat(300),
      tabId: 't'.repeat(100),
      sequence: -1,
    });

    expect(context).toEqual({
      url: 'https://example.com/docs',
      title: 'A'.repeat(256),
      tabId: 't'.repeat(64),
      sequence: 0,
    });
    expect(
      normalizePageContext({ url: 'ftp://example.com/path', title: 'Unsafe' })
    ).toBeNull();
    expect(
      normalizePageContext({
        url: 'https://user:password@example.com/path',
        title: 'Unsafe',
      })
    ).toBeNull();
  });
});

describe('#onLocationChangeListener', () => {
  it('emits the initial page and normalized route changes once', async () => {
    window.sessionStorage.clear();
    window.history.replaceState({}, '', '/initial?utm_source=chat#intro');
    document.title = 'Initial';
    IFrameHelper.events.onLocationChange.mockClear();

    onLocationChangeListener();

    expect(IFrameHelper.events.onLocationChange).toHaveBeenCalledWith({
      referrerURL: `${window.location.origin}/initial?utm_source=chat#intro`,
      referrerHost: window.location.host,
      pageContext: {
        url: `${window.location.origin}/initial`,
        title: 'Initial',
        tabId: expect.any(String),
        sequence: 0,
      },
    });

    window.history.pushState({}, '', '/next?utm_source=chat#details');
    expect(IFrameHelper.events.onLocationChange).toHaveBeenLastCalledWith({
      referrerURL: `${window.location.origin}/next?utm_source=chat#details`,
      referrerHost: window.location.host,
      pageContext: {
        url: `${window.location.origin}/next`,
        title: 'Initial',
        tabId: expect.any(String),
        sequence: 1,
      },
    });

    window.history.replaceState({}, '', '/next?utm_source=other#details');
    expect(IFrameHelper.events.onLocationChange).toHaveBeenLastCalledWith({
      referrerURL: `${window.location.origin}/next?utm_source=other#details`,
      referrerHost: window.location.host,
    });

    document.title = 'Updated';
    await vi.waitFor(() =>
      expect(IFrameHelper.events.onLocationChange).toHaveBeenLastCalledWith({
        referrerURL: `${window.location.origin}/next?utm_source=other#details`,
        referrerHost: window.location.host,
        pageContext: {
          url: `${window.location.origin}/next`,
          title: 'Updated',
          tabId: expect.any(String),
          sequence: 2,
        },
      })
    );
  });
});
