/**
 * Add information about the environment axe was run in.
 * @return {Object}
 */
function getEnvironmentData(win = window) {
  // TODO: remove parameter once we are testing axe-core in jsdom and other
  // supported environments
  const {
    screen = {},
    navigator = {},
    location = {},
    innerHeight,
    innerWidth
  } = win;

  const orientation =
    screen.msOrientation || screen.orientation || screen.mozOrientation || {};

  return {
    testEngine: {
      name: 'axe-core',
      version: axe.version
    },
    testRunner: {
      name: axe._audit.brand
    },
    testEnvironment: {
      userAgent: navigator.userAgent,
      windowWidth: innerWidth,
      windowHeight: innerHeight,
      orientationAngle: orientation.angle,
      orientationType: orientation.type
    },
    timestamp: new Date().toISOString(),
    url: location.href
  };
}

export default getEnvironmentData;
