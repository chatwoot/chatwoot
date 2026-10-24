import {
  fitHolderToViewport,
  getHolderStyleForViewport,
  startFittingHolderToViewport,
  stopFittingHolderToViewport,
} from '../visualViewportHelper';

describe('visualViewportHelper', () => {
  let holder;
  let viewport;

  beforeEach(() => {
    holder = document.createElement('div');
    viewport = new EventTarget();
    viewport.height = 400;
    viewport.offsetTop = 120;
    window.visualViewport = viewport;
    window.matchMedia = vi.fn(() => ({ matches: true }));
    window.$chatwoot = { isOpen: true };
  });

  afterEach(() => {
    stopFittingHolderToViewport(holder);
    delete window.visualViewport;
    delete window.matchMedia;
    delete window.$chatwoot;
  });

  describe('#getHolderStyleForViewport', () => {
    it('sizes the holder to the visual viewport', () => {
      expect(
        getHolderStyleForViewport({ height: 512.5, offsetTop: 0 })
      ).toEqual({ height: '512.5px', top: '0px' });
      expect(
        getHolderStyleForViewport({ height: 300, offsetTop: 240 })
      ).toEqual({ height: '300px', top: '240px' });
    });
  });

  describe('#fitHolderToViewport', () => {
    it('fits the holder when the widget is open full screen', () => {
      fitHolderToViewport(holder);

      expect(window.matchMedia).toHaveBeenCalledWith('(max-width: 666.98px)');
      expect(holder.style.height).toBe('400px');
      expect(holder.style.top).toBe('120px');
    });

    it('clears the holder style on wider screens', () => {
      holder.style.height = '400px';
      holder.style.top = '120px';
      window.matchMedia.mockReturnValue({ matches: false });

      fitHolderToViewport(holder);

      expect(holder.style.height).toBe('');
      expect(holder.style.top).toBe('');
    });

    it('clears the holder style in the unread messages view', () => {
      holder.style.height = '400px';
      holder.style.top = '120px';
      holder.classList.add('has-unread-view');

      fitHolderToViewport(holder);

      expect(holder.style.height).toBe('');
      expect(holder.style.top).toBe('');
    });

    it('clears the holder style when the widget is closed', () => {
      holder.style.height = '400px';
      window.$chatwoot.isOpen = false;

      fitHolderToViewport(holder);

      expect(holder.style.height).toBe('');
    });

    it('does nothing when the browser has no visual viewport', () => {
      delete window.visualViewport;
      holder.style.height = '50%';

      fitHolderToViewport(holder);

      expect(holder.style.height).toBe('50%');
      expect(holder.style.top).toBe('');
    });
  });

  describe('#startFittingHolderToViewport', () => {
    it('follows visual viewport resize and scroll events', () => {
      startFittingHolderToViewport(holder);
      expect(holder.style.height).toBe('400px');

      viewport.height = 250;
      viewport.dispatchEvent(new Event('resize'));
      expect(holder.style.height).toBe('250px');

      viewport.offsetTop = 300;
      viewport.dispatchEvent(new Event('scroll'));
      expect(holder.style.top).toBe('300px');
    });

    it('adds the listeners only once', () => {
      const addEventListener = vi.spyOn(viewport, 'addEventListener');

      startFittingHolderToViewport(holder);
      startFittingHolderToViewport(holder);

      expect(addEventListener).toHaveBeenCalledTimes(2);
      expect(addEventListener).toHaveBeenCalledWith(
        'resize',
        expect.any(Function)
      );
      expect(addEventListener).toHaveBeenCalledWith(
        'scroll',
        expect.any(Function)
      );
    });

    it('does nothing when the browser has no visual viewport', () => {
      delete window.visualViewport;

      startFittingHolderToViewport(holder);

      expect(holder.style.height).toBe('');
    });
  });

  describe('#stopFittingHolderToViewport', () => {
    it('removes the listeners and restores the stylesheet layout', () => {
      startFittingHolderToViewport(holder);

      stopFittingHolderToViewport(holder);
      expect(holder.style.height).toBe('');
      expect(holder.style.top).toBe('');

      viewport.height = 250;
      viewport.dispatchEvent(new Event('resize'));
      expect(holder.style.height).toBe('');
    });
  });
});
