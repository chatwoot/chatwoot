const { spawn } = require('child_process');

const rebuildIfDarwin = () => {
  if (process.platform !== 'darwin') {
    console.log();
    console.log(`Skipping 'fsevents' build as platform ${process.platform} is not supported`);
    process.exit(0);
  } else {
    spawn('node-gyp', ['rebuild'], { stdio: 'inherit' });
  }
};

rebuildIfDarwin();
