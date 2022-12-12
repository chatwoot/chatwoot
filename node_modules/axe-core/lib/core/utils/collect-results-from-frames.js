import queue from './queue';
import sendCommandToFrame from './send-command-to-frame';
import mergeResults from './merge-results';
import getSelector from './get-selector';

/**
 * Sends a message to axe running in frames to start analysis and collate results (via `mergeResults`)
 * @private
 * @param  {Context}  parentContent   The resolved Context object
 * @param  {Object}   options   Options object (as passed to `runRules`)
 * @param  {string}   command   Command sent to all frames
 * @param  {Array}    parameter Array of values to be passed along side the command
 * @param  {Function} callback  Function to call when results from all frames have returned
 */
function collectResultsFromFrames(
  parentContent,
  options,
  command,
  parameter,
  resolve,
  reject
) {
  var q = queue();
  var frames = parentContent.frames;

  // Tell each axe running in each frame to collect results
  frames.forEach(frame => {
    const tabindex = parseInt(frame.node.getAttribute('tabindex'), 10);
    const focusable = isNaN(tabindex) || tabindex >= 0;

    const rect = frame.node.getBoundingClientRect();
    let width = parseInt(frame.node.getAttribute('width'), 10);
    let height = parseInt(frame.node.getAttribute('height'), 10);
    width = isNaN(width) ? rect.width : width;
    height = isNaN(height) ? rect.height : height;

    var params = {
      options: options,
      command: command,
      parameter: parameter,
      context: {
        initiator: false,

        // if any parent iframe is not focusable then the entire
        // iframe stack is not focusable (even if the descendant
        // iframe has tabindex=0 on it)
        focusable: parentContent.focusable === false ? false : focusable,
        boundingClientRect: {
          width: width,
          height: height
        },
        page: parentContent.page,
        include: frame.include || [],
        exclude: frame.exclude || []
      }
    };

    q.defer((res, rej) => {
      var node = frame.node;
      sendCommandToFrame(
        node,
        params,
        data => {
          if (data) {
            return res({
              results: data,
              frameElement: node,
              frame: getSelector(node)
            });
          }
          res(null);
        },
        rej
      );
    });
  });

  // Combine results from all frames and give it back
  q.then(data => {
    resolve(mergeResults(data, options));
  }).catch(reject);
}

export default collectResultsFromFrames;
