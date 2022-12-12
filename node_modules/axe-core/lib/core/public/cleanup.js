function cleanup(resolve, reject) {
  resolve = resolve || function res() {};
  reject = reject || axe.log;

  if (!axe._audit) {
    throw new Error('No audit configured');
  }

  var q = axe.utils.queue();
  // If a plugin fails it's cleanup, we still want the others to run
  var cleanupErrors = [];

  Object.keys(axe.plugins).forEach(key => {
    q.defer(res => {
      var rej = function rej(err) {
        cleanupErrors.push(err);
        res();
      };
      try {
        axe.plugins[key].cleanup(res, rej);
      } catch (err) {
        rej(err);
      }
    });
  });

  var flattenedTree = axe.utils.getFlattenedTree(document.body);

  axe.utils.querySelectorAll(flattenedTree, 'iframe, frame').forEach(node => {
    q.defer((res, rej) => {
      return axe.utils.sendCommandToFrame(
        node.actualNode,
        {
          command: 'cleanup-plugin'
        },
        res,
        rej
      );
    });
  });

  q.then(results => {
    if (cleanupErrors.length === 0) {
      resolve(results);
    } else {
      reject(cleanupErrors);
    }
  }).catch(reject);
}

export default cleanup;
