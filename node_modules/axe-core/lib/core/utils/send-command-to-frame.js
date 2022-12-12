import getSelector from './get-selector';
import respondable from './respondable';
import log from '../log';

function err(message, node) {
  var selector;
  // TODO: es-modules_tree
  if (axe._tree) {
    selector = getSelector(node);
  }
  return new Error(message + ': ' + (selector || node));
}

/**
 * Sends a command to an instance of axe in the specified frame
 * @param  {Element}  node       The frame element to send the message to
 * @param  {Object}   parameters Parameters to pass to the frame
 * @param  {Function} callback   Function to call when results from the frame has returned
 */
function sendCommandToFrame(node, parameters, resolve, reject) {
  var win = node.contentWindow;
  if (!win) {
    log('Frame does not have a content window', node);
    resolve(null);
    return;
  }

  // give the frame .5s to respond to 'axe.ping', else log failed response
  var timeout = setTimeout(() => {
    // This double timeout is important for allowing iframes to respond
    // DO NOT REMOVE
    timeout = setTimeout(() => {
      if (!parameters.debug) {
        resolve(null);
      } else {
        reject(err('No response from frame', node));
      }
    }, 0);
  }, 500);

  // send 'axe.ping' to the frame
  respondable(win, 'axe.ping', null, undefined, () => {
    clearTimeout(timeout);

    // Give axe 60s (or user-supplied value) to respond to 'axe.start'
    var frameWaitTime =
      (parameters.options && parameters.options.frameWaitTime) || 60000;

    timeout = setTimeout(function collectResultFramesTimeout() {
      reject(err('Axe in frame timed out', node));
    }, frameWaitTime);

    // send 'axe.start' and send the callback if it responded
    respondable(win, 'axe.start', parameters, undefined, data => {
      clearTimeout(timeout);
      if (data instanceof Error === false) {
        resolve(data);
      } else {
        reject(data);
      }
    });
  });
}

export default sendCommandToFrame;
