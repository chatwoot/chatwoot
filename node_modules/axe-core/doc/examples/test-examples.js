const { readdirSync, statSync } = require('fs');
const { join } = require('path');
const execa = require('execa');
const exampleDirs = readdirSync(__dirname)
  .map(dir => join(__dirname, dir))
  .filter(dir => statSync(dir).isDirectory());

const config = { stdio: 'inherit', shell: true };

// run npm install in parallel
async function install(dir) {
  await execa('npm install', { cwd: dir, ...config });

  // override the package version of axe-core with the local version.
  // this allows the examples to stay examples while allowing us to
  // test them against our changes
  return await execa('npm install --no-save file:..\\/..\\/..\\/', {
    cwd: dir,
    ...config
  });
}

// run tests synchronously so we can see which one threw an error
function test(dir) {
  return execa('npm test', { cwd: dir, ...config });
}

Promise.all(exampleDirs.map(install))
  .then(async () => {
    for (const dir of exampleDirs) {
      await test(dir);
    }

    // Return successful exit
    process.exit();
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
