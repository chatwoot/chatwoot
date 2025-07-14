export function shouldPolyfill(): boolean {
  const browserVersionCompatList: { [browser: string]: number } = {
    Firefox: 46,
    Edge: 13,
  }

  // Unfortunately IE doesn't follow the same pattern as other browsers, so we
  // need to check `isIE11` differently.
  // @ts-expect-error
  const isIE11 = !!window.MSInputMethodContext && !!document.documentMode

  const userAgent = navigator.userAgent.split(' ')
  const [browser, version] = userAgent[userAgent.length - 1].split('/')

  return (
    isIE11 ||
    (browserVersionCompatList[browser] !== undefined &&
      browserVersionCompatList[browser] >= parseInt(version))
  )
}

// appName = Netscape IE / Edge
// edge 13 Edge/13... same as FF
