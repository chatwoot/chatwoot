// @flow

export function resolve(
  dirname: string,
  moduleName: string,
  absoluteImports: boolean | string,
): string {
  if (absoluteImports === false) return moduleName;

  throw new Error(
    `"absoluteImports" is not supported in bundles prepared for the browser.`,
  );
}

// eslint-disable-next-line no-unused-vars
export function has(basedir: string, name: string) {
  return true;
}

// eslint-disable-next-line no-unused-vars
export function logMissing(missingDeps: Set<string>) {}

// eslint-disable-next-line no-unused-vars
export function laterLogMissing(missingDeps: Set<string>) {}
