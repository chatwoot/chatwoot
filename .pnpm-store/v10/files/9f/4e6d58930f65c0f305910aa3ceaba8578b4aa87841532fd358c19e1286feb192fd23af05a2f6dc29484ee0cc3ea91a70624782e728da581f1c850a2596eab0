/**
 * Register event listener on document that fires when:
 * * tab change or tab close (in mobile or desktop)
 * * click back / forward button
 * * click any link or perform any other navigation action
 * * soft refresh / hard refresh
 *
 * adapted from https://stackoverflow.com/questions/3239834/window-onbeforeunload-not-working-on-the-ipad/52864508#52864508,
 */
export const onPageLeave = (cb: (...args: unknown[]) => void) => {
  let unloaded = false // prevents double firing if both are supported

  window.addEventListener('pagehide', () => {
    if (unloaded) return
    unloaded = true
    cb()
  })

  // using document instead of window because of bug affecting browsers before safari 14 (detail in footnotes https://caniuse.com/?search=visibilitychange)
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState == 'hidden') {
      if (unloaded) return
      unloaded = true
      cb()
    } else {
      unloaded = false
    }
  })
}
