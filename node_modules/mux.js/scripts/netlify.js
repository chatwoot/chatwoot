const shell = require('shelljs');

// clone vhs
shell.exec('git clone https://github.com/videojs/http-streaming');
shell.cd('http-streaming');

// install vhs and link in the local version of mux.js
shell.exec('npm ci');
shell.exec('npm link ../');

// run the vhs netlify script so that we can use
// the vhs netlify page with this local mux.js
shell.exec('npm run netlify');

// move the vhs deploy directory to the project root
shell.cp('-R', 'deploy',  '../');

// cleanup by removing the cloned vhs directory
shell.cd('..');
shell.rm('-rf', 'http-streaming');
