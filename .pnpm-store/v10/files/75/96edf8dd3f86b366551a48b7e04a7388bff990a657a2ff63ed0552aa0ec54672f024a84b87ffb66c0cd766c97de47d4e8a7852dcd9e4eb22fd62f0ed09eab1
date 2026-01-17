const CoverageProviderMap = {
  v8: "@vitest/coverage-v8",
  istanbul: "@vitest/coverage-istanbul"
};
async function resolveCoverageProviderModule(options, loader) {
  if (!options?.enabled || !options.provider) {
    return null;
  }
  const provider = options.provider;
  if (provider === "v8" || provider === "istanbul") {
    let builtInModule = CoverageProviderMap[provider];
    if (provider === "v8" && loader.isBrowser) {
      builtInModule += "/browser";
    }
    const { default: coverageModule } = await loader.executeId(builtInModule);
    if (!coverageModule) {
      throw new Error(
        `Failed to load ${CoverageProviderMap[provider]}. Default export is missing.`
      );
    }
    return coverageModule;
  }
  let customProviderModule;
  try {
    customProviderModule = await loader.executeId(options.customProviderModule);
  } catch (error) {
    throw new Error(
      `Failed to load custom CoverageProviderModule from ${options.customProviderModule}`,
      { cause: error }
    );
  }
  if (customProviderModule.default == null) {
    throw new Error(
      `Custom CoverageProviderModule loaded from ${options.customProviderModule} was not the default export`
    );
  }
  return customProviderModule.default;
}
async function getCoverageProvider(options, loader) {
  const coverageModule = await resolveCoverageProviderModule(options, loader);
  if (coverageModule) {
    return coverageModule.getProvider();
  }
  return null;
}
async function startCoverageInsideWorker(options, loader, runtimeOptions) {
  const coverageModule = await resolveCoverageProviderModule(options, loader);
  if (coverageModule) {
    return coverageModule.startCoverage?.(runtimeOptions);
  }
  return null;
}
async function takeCoverageInsideWorker(options, loader) {
  const coverageModule = await resolveCoverageProviderModule(options, loader);
  if (coverageModule) {
    return coverageModule.takeCoverage?.();
  }
  return null;
}
async function stopCoverageInsideWorker(options, loader, runtimeOptions) {
  const coverageModule = await resolveCoverageProviderModule(options, loader);
  if (coverageModule) {
    return coverageModule.stopCoverage?.(runtimeOptions);
  }
  return null;
}

export { CoverageProviderMap as C, stopCoverageInsideWorker as a, getCoverageProvider as g, startCoverageInsideWorker as s, takeCoverageInsideWorker as t };
