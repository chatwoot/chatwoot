import { IFrameHelper } from '../IFrameHelper';
import { widgetHolder } from '../bubbleHelpers';
import {
  fitHolderToViewport,
  startFittingHolderToViewport,
  stopFittingHolderToViewport,
} from '../visualViewportHelper';

vi.mock('../visualViewportHelper', () => ({
  fitHolderToViewport: vi.fn(),
  startFittingHolderToViewport: vi.fn(),
  stopFittingHolderToViewport: vi.fn(),
}));

describe('IFrameHelper visual viewport fit', () => {
  beforeEach(() => {
    vi.spyOn(IFrameHelper, 'sendMessage').mockImplementation(() => {});
    window.$chatwoot = { isOpen: true };
  });

  afterEach(() => {
    delete window.$chatwoot;
  });

  it('starts fitting the holder when the widget opens', () => {
    IFrameHelper.events.onBubbleToggle(true);

    expect(startFittingHolderToViewport).toHaveBeenCalledWith(widgetHolder);
    expect(stopFittingHolderToViewport).not.toHaveBeenCalled();
  });

  it('stops fitting the holder when the widget closes', () => {
    IFrameHelper.events.onBubbleToggle(false);

    expect(stopFittingHolderToViewport).toHaveBeenCalledWith(widgetHolder);
    expect(startFittingHolderToViewport).not.toHaveBeenCalled();
  });

  it('refits the holder when the unread view expands to the full widget', () => {
    widgetHolder.classList.add('woot-widget-holder', 'has-unread-view');
    document.body.appendChild(widgetHolder);

    IFrameHelper.events.resetUnreadMode();

    expect(widgetHolder.classList.contains('has-unread-view')).toBe(false);
    expect(fitHolderToViewport).toHaveBeenCalledWith(widgetHolder);
  });
});
