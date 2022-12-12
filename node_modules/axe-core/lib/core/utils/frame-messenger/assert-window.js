import assert from '../assert';

export function assertIsParentWindow(win) {
  assetNotGlobalWindow(win);
  assert(
    window.parent === win,
    'Source of the response must be the parent window.'
  );
}

export function assertIsFrameWindow(win) {
  assetNotGlobalWindow(win);
  assert(
    win.parent === window,
    'Respondable target must be a frame in the current window'
  );
}

export function assetNotGlobalWindow(win) {
  assert(window !== win, 'Messages can not be sent to the same window.');
}
