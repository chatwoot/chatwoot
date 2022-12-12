import { respondable } from '../../core/utils';

function frameTestedEvaluate(node, options) {
  const resolve = this.async();
  const { isViolation, timeout } = Object.assign(
    { isViolation: false, timeout: 500 },
    options
  );

  // give the frame .5s to respond to 'axe.ping', else log failed response
  let timer = setTimeout(() => {
    // This double timeout is important for allowing iframes to respond
    // DO NOT REMOVE
    timer = setTimeout(() => {
      timer = null;
      resolve(isViolation ? false : undefined);
    }, 0);
  }, timeout);

  respondable(node.contentWindow, 'axe.ping', null, undefined, () => {
    if (timer !== null) {
      clearTimeout(timer);
      resolve(true);
    }
  });
}

export default frameTestedEvaluate;
