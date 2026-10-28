import {
  captureTimelineAnchor,
  getTimelineEntries,
  getUnreadScrollTop,
} from '../campaignScrollAnchor';

describe('campaign timeline scroll anchor', () => {
  let panel;
  let message;
  let messageTop;

  beforeEach(() => {
    panel = document.createElement('div');
    message = document.createElement('li');
    message.id = 'message42';
    message.dataset.messageId = '42';
    panel.appendChild(message);
    panel.scrollTop = 200;
    messageTop = 10;
    panel.getBoundingClientRect = () => ({ top: 0 });
    message.getBoundingClientRect = () => ({
      top: messageTop,
      bottom: messageTop + 50,
    });
  });

  it('does not move the viewport when entries are inserted below it', () => {
    const restore = captureTimelineAnchor(panel);
    panel.appendChild(document.createElement('li'));
    restore();
    expect(panel.scrollTop).toBe(200);
  });

  it('anchors unread scrolling independently of campaign heights below it', () => {
    messageTop = 500;
    Object.defineProperty(panel, 'clientHeight', { value: 400 });
    Object.defineProperty(panel, 'scrollHeight', { value: 2000 });
    const campaign = document.createElement('li');
    campaign.id = 'campaign-recipient-1';
    Object.defineProperty(campaign, 'scrollHeight', { value: 800 });
    panel.appendChild(campaign);
    expect(getUnreadScrollTop(panel, 42)).toBe(500);
    panel.getBoundingClientRect = () => ({ top: 100 });
    expect(getUnreadScrollTop(panel, 42)).toBe(400);
  });

  it('compensates only for content inserted above the visible message', () => {
    const restore = captureTimelineAnchor(panel);
    messageTop += 80;
    restore();
    expect(panel.scrollTop).toBe(280);
  });

  it('preserves the deep-linked message when entries are inserted on both sides', () => {
    const earlier = document.createElement('li');
    earlier.id = 'campaign-recipient-1';
    earlier.getBoundingClientRect = () => ({ top: 0, bottom: 10 });
    panel.prepend(earlier);
    const restore = captureTimelineAnchor(panel, '42');
    panel.appendChild(document.createElement('li'));
    messageTop += 30;
    restore();
    expect(panel.scrollTop).toBe(230);
  });

  it('does not double-adjust when browser scroll anchoring already preserved the position', () => {
    const restore = captureTimelineAnchor(panel);
    panel.scrollTop += 80;
    restore();
    expect(panel.scrollTop).toBe(280);
  });

  it('does not adjust after the anchor is removed', () => {
    const restore = captureTimelineAnchor(panel);
    message.remove();
    restore();
    expect(panel.scrollTop).toBe(200);
  });
  it('selects the final timeline entry rather than an earlier campaign', () => {
    const campaign = document.createElement('li');
    campaign.id = 'campaign-recipient-1';
    panel.prepend(campaign);
    expect(getTimelineEntries(panel).at(-1)).toBe(message);
    panel.appendChild(campaign);
    expect(getTimelineEntries(panel).at(-1)).toBe(campaign);
  });
});
