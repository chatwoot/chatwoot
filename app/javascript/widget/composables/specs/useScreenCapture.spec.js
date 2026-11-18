import { IFrameHelper } from 'widget/helpers/utils';
import { useScreenCapture } from '../useScreenCapture';

vi.mock('widget/helpers/utils', () => ({
  IFrameHelper: { isIFrame: vi.fn(), sendMessage: vi.fn() },
}));

describe('useScreenCapture', () => {
  const track = { stop: vi.fn() };
  const stream = { getTracks: () => [track] };
  const calls = [];

  beforeEach(() => {
    calls.length = 0;
    vi.useFakeTimers();
    IFrameHelper.isIFrame.mockReturnValue(true);
    IFrameHelper.sendMessage.mockImplementation(({ event, isHidden }) =>
      calls.push(`${event}:${isHidden}`)
    );
    track.stop.mockImplementation(() => calls.push('stop'));
    navigator.mediaDevices = {
      getDisplayMedia: vi.fn(async () => {
        calls.push('getDisplayMedia');
        return stream;
      }),
    };
    vi.spyOn(HTMLMediaElement.prototype, 'play').mockImplementation(
      async () => {
        calls.push('play');
      }
    );
    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue({
      drawImage: () => calls.push('drawImage'),
    });
    HTMLCanvasElement.prototype.toBlob = function toBlob(callback, type) {
      callback(new Blob(['frame'], { type }));
    };
  });

  afterEach(() => vi.useRealTimers());

  it('asks for the screen first, hides the widget for the frame without closing it', async () => {
    const { captureScreen } = useScreenCapture();

    const result = captureScreen();
    await vi.runAllTimersAsync();
    const file = await result;

    expect(calls).toEqual([
      'getDisplayMedia',
      'play',
      'setCaptureHidden:true',
      'drawImage',
      'stop',
      'setCaptureHidden:false',
    ]);
    expect(file.type).toBe('image/png');
    expect(file.name).toMatch(/^screenshot-\d+\.png$/);
  });

  it('rejects and shows the widget again when the frame cannot be encoded', async () => {
    HTMLCanvasElement.prototype.toBlob = callback => callback(null);
    const { captureScreen } = useScreenCapture();

    const result = captureScreen();
    const assertion = expect(result).rejects.toThrow('Could not encode');
    await vi.runAllTimersAsync();
    await assertion;

    expect(calls.at(-1)).toBe('setCaptureHidden:false');
  });

  it('resolves with null and leaves the widget alone when the picker is closed', async () => {
    navigator.mediaDevices.getDisplayMedia.mockRejectedValue(
      new DOMException('Permission denied', 'NotAllowedError')
    );
    const { captureScreen } = useScreenCapture();

    expect(await captureScreen()).toBeNull();
    expect(IFrameHelper.sendMessage).not.toHaveBeenCalled();
  });

  it('shows the widget again and stops the stream when no frame arrives', async () => {
    HTMLMediaElement.prototype.play.mockImplementation(
      () => new Promise(() => {})
    );
    const { captureScreen } = useScreenCapture();

    const result = captureScreen();
    const assertion = expect(result).rejects.toThrow('Timed out');
    await vi.runAllTimersAsync();
    await assertion;

    expect(calls).toEqual([
      'getDisplayMedia',
      'setCaptureHidden:true',
      'stop',
      'setCaptureHidden:false',
    ]);
  });
});
