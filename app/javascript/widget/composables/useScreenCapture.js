import { useStore } from 'vuex';
import { IFrameHelper } from 'widget/helpers/utils';

// Time the host page needs to repaint without the widget before the frame is taken.
const HIDE_DELAY_MS = 300;
const FRAME_TIMEOUT_MS = 3000;

const CANCEL_ERRORS = ['NotAllowedError', 'AbortError'];

const wait = ms =>
  new Promise(resolve => {
    setTimeout(resolve, ms);
  });

const timeout = ms =>
  wait(ms).then(() => {
    throw new Error('Timed out waiting for the screen frame');
  });

const frameToFile = video => {
  const canvas = document.createElement('canvas');
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  canvas.getContext('2d').drawImage(video, 0, 0);
  return new Promise((resolve, reject) => {
    canvas.toBlob(blob => {
      if (!blob) {
        reject(new Error('Could not encode the screen frame'));
        return;
      }
      resolve(
        new File([blob], `screenshot-${Date.now()}.png`, { type: 'image/png' })
      );
    }, 'image/png');
  });
};

export function useScreenCapture() {
  const store = useStore();
  const isScreenCaptureSupported = Boolean(
    navigator.mediaDevices?.getDisplayMedia
  );

  // Resolves with a PNG File, or with null when the user closes the picker.
  const captureScreen = async () => {
    let stream;
    try {
      // Called first, while the click still counts as a user gesture.
      stream = await navigator.mediaDevices.getDisplayMedia({
        video: true,
        audio: false,
        preferCurrentTab: true,
        selfBrowserSurface: 'include',
      });
    } catch (error) {
      if (CANCEL_ERRORS.includes(error.name)) return null;
      throw error;
    }

    // The video starts before the widget hides, so the repaint without the widget reaches
    // it as the latest frame. requestAnimationFrame is not used: it can stop in the
    // hidden iframe.
    const video = document.createElement('video');
    video.muted = true;
    video.srcObject = stream;
    const playing = video.play();
    const isEmbedded = IFrameHelper.isIFrame();
    if (isEmbedded) IFrameHelper.sendMessage({ event: 'closeWindow' });
    try {
      await Promise.race([playing, timeout(FRAME_TIMEOUT_MS)]);
      await wait(HIDE_DELAY_MS);
      return await frameToFile(video);
    } finally {
      stream.getTracks().forEach(track => track.stop());
      // toggleBubble inverts the state, so it is sent only when the widget is still closed:
      // the visitor can reopen it from the launcher during the capture.
      if (isEmbedded && !store.getters['appConfig/getIsWidgetOpen']) {
        IFrameHelper.sendMessage({ event: 'toggleBubble' });
      }
    }
  };

  return { isScreenCaptureSupported, captureScreen };
}
