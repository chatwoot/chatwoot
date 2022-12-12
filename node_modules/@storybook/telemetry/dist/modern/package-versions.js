import path from 'path';
export const getActualPackageVersions = async packages => {
  const packageNames = Object.keys(packages);
  return Promise.all(packageNames.map(getActualPackageVersion));
};
export const getActualPackageVersion = async packageName => {
  try {
    // eslint-disable-next-line import/no-dynamic-require,global-require
    const packageJson = require(path.join(packageName, 'package.json'));

    return {
      name: packageName,
      version: packageJson.version
    };
  } catch (err) {
    return {
      name: packageName,
      version: null
    };
  }
};