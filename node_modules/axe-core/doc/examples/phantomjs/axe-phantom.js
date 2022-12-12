/*global window, phantom */
var PATH_TO_AXE = 'node_modules/axe-core/axe.min.js';

var args = require('system').args;
var fs = require('fs');
var page = require('webpage').create();

if (args.length < 2) {
  console.log('axe-phantomjs.js accepts 1 argument, the URL to test');
  phantom.exit(1);
}

console.log('Testing, please wait...');

page.open(args[1], function(status) {
  // Check for page load success
  if (status !== 'success') {
    console.log('Unable to access network');
    return;
  }

  page.injectJs(PATH_TO_AXE);
  page.framesName.forEach(function(name) {
    page.switchToFrame(name);
    page.injectJs(PATH_TO_AXE);
  });
  page.switchToMainFrame();
  page.evaluateAsync(function() {
    /*global axe */
    axe.run({ include: ['#page'] }, function(err, results) {
      if (err) {
        throw err;
      }
      window.callPhantom(results);
    });
  });

  page.onCallback = function(msg) {
    if (args[2]) {
      fs.write(args[2], JSON.stringify(msg, null, '  '), 'w');
    } else {
      if (msg.violations.length) {
        console.log(JSON.stringify(msg.violations, null, '  '));
      } else {
        console.log('No violations found!');
      }
    }

    // NOTE: to fail the test when violations are found, uncomment the line below.
    // phantom.exit(msg.violations.length);
    phantom.exit(0);
  };
});
