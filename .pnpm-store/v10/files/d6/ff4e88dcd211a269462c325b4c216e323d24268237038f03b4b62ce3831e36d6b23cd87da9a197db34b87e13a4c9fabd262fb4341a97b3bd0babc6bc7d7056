import { existsSync, promises, readdirSync, writeFileSync } from 'node:fs';
import { c as coverageConfigDefaults, r as resolveCoverageReporters, m as mm } from './chunks/resolveConfig.BT-MMQUD.js';
import { resolve, relative } from 'pathe';
import c from 'tinyrainbow';
import 'node:crypto';
import '@vitest/utils';
import 'node:fs/promises';
import 'node:module';
import 'node:path';
import 'node:process';
import 'node:url';
import 'node:assert';
import 'node:v8';
import 'node:util';
import './chunks/constants.fzPh7AOq.js';
import 'node:os';
import './chunks/typechecker.CdcjdhoT.js';
import 'std-env';
import 'node:perf_hooks';
import '@vitest/utils/source-map';
import 'tinyexec';
import '@vitest/runner/utils';
import 'vite';
import 'fs';
import 'node:tty';
import './chunks/_commonjsHelpers.BFTU3MAI.js';
import 'util';
import 'path';
import 'node:events';
import './chunks/index.TH3f4LSA.js';
import 'tinypool';
import 'node:worker_threads';
import './path.js';
import 'vite-node/utils';

const THRESHOLD_KEYS = [
  "lines",
  "functions",
  "statements",
  "branches"
];
const GLOBAL_THRESHOLDS_KEY = "global";
const DEFAULT_PROJECT = Symbol.for("default-project");
let uniqueId = 0;
class BaseCoverageProvider {
  ctx;
  name;
  version;
  options;
  coverageFiles = /* @__PURE__ */ new Map();
  pendingPromises = [];
  coverageFilesDirectory;
  _initialize(ctx) {
    this.ctx = ctx;
    if (ctx.version !== this.version) {
      ctx.logger.warn(
        c.yellow(
          `Loaded ${c.inverse(c.yellow(` vitest@${ctx.version} `))} and ${c.inverse(c.yellow(` @vitest/coverage-${this.name}@${this.version} `))}.
Running mixed versions is not supported and may lead into bugs
Update your dependencies and make sure the versions match.`
        )
      );
    }
    const config = ctx.config.coverage;
    this.options = {
      ...coverageConfigDefaults,
      // User's options
      ...config,
      // Resolved fields
      provider: this.name,
      reportsDirectory: resolve(
        ctx.config.root,
        config.reportsDirectory || coverageConfigDefaults.reportsDirectory
      ),
      reporter: resolveCoverageReporters(
        config.reporter || coverageConfigDefaults.reporter
      ),
      thresholds: config.thresholds && {
        ...config.thresholds,
        lines: config.thresholds["100"] ? 100 : config.thresholds.lines,
        branches: config.thresholds["100"] ? 100 : config.thresholds.branches,
        functions: config.thresholds["100"] ? 100 : config.thresholds.functions,
        statements: config.thresholds["100"] ? 100 : config.thresholds.statements
      }
    };
    const shard = this.ctx.config.shard;
    const tempDirectory = `.tmp${shard ? `-${shard.index}-${shard.count}` : ""}`;
    this.coverageFilesDirectory = resolve(
      this.options.reportsDirectory,
      tempDirectory
    );
  }
  createCoverageMap() {
    throw new Error("BaseReporter's createCoverageMap was not overwritten");
  }
  async generateReports(_, __) {
    throw new Error("BaseReporter's generateReports was not overwritten");
  }
  async parseConfigModule(_) {
    throw new Error("BaseReporter's parseConfigModule was not overwritten");
  }
  resolveOptions() {
    return this.options;
  }
  async clean(clean = true) {
    if (clean && existsSync(this.options.reportsDirectory)) {
      await promises.rm(this.options.reportsDirectory, {
        recursive: true,
        force: true,
        maxRetries: 10
      });
    }
    if (existsSync(this.coverageFilesDirectory)) {
      await promises.rm(this.coverageFilesDirectory, {
        recursive: true,
        force: true,
        maxRetries: 10
      });
    }
    await promises.mkdir(this.coverageFilesDirectory, { recursive: true });
    this.coverageFiles = /* @__PURE__ */ new Map();
    this.pendingPromises = [];
  }
  onAfterSuiteRun({ coverage, transformMode, projectName, testFiles }) {
    if (!coverage) {
      return;
    }
    if (transformMode !== "web" && transformMode !== "ssr" && transformMode !== "browser") {
      throw new Error(`Invalid transform mode: ${transformMode}`);
    }
    let entry = this.coverageFiles.get(projectName || DEFAULT_PROJECT);
    if (!entry) {
      entry = { web: {}, ssr: {}, browser: {} };
      this.coverageFiles.set(projectName || DEFAULT_PROJECT, entry);
    }
    const testFilenames = testFiles.join();
    const filename = resolve(
      this.coverageFilesDirectory,
      `coverage-${uniqueId++}.json`
    );
    entry[transformMode][testFilenames] = filename;
    const promise = promises.writeFile(filename, JSON.stringify(coverage), "utf-8");
    this.pendingPromises.push(promise);
  }
  async readCoverageFiles({ onFileRead, onFinished, onDebug }) {
    let index = 0;
    const total = this.pendingPromises.length;
    await Promise.all(this.pendingPromises);
    this.pendingPromises = [];
    for (const [projectName, coveragePerProject] of this.coverageFiles.entries()) {
      for (const [transformMode, coverageByTestfiles] of Object.entries(coveragePerProject)) {
        const filenames = Object.values(coverageByTestfiles);
        const project = this.ctx.getProjectByName(projectName);
        for (const chunk of this.toSlices(filenames, this.options.processingConcurrency)) {
          if (onDebug.enabled) {
            index += chunk.length;
            onDebug("Covered files %d/%d", index, total);
          }
          await Promise.all(
            chunk.map(async (filename) => {
              const contents = await promises.readFile(filename, "utf-8");
              const coverage = JSON.parse(contents);
              onFileRead(coverage);
            })
          );
        }
        await onFinished(project, transformMode);
      }
    }
  }
  async cleanAfterRun() {
    this.coverageFiles = /* @__PURE__ */ new Map();
    await promises.rm(this.coverageFilesDirectory, { recursive: true });
    if (readdirSync(this.options.reportsDirectory).length === 0) {
      await promises.rm(this.options.reportsDirectory, { recursive: true });
    }
  }
  async onTestFailure() {
    if (!this.options.reportOnFailure) {
      await this.cleanAfterRun();
    }
  }
  async reportCoverage(coverageMap, { allTestsRun }) {
    await this.generateReports(
      coverageMap || this.createCoverageMap(),
      allTestsRun
    );
    const keepResults = !this.options.cleanOnRerun && this.ctx.config.watch;
    if (!keepResults) {
      await this.cleanAfterRun();
    }
  }
  async reportThresholds(coverageMap, allTestsRun) {
    const resolvedThresholds = this.resolveThresholds(coverageMap);
    this.checkThresholds(resolvedThresholds);
    if (this.options.thresholds?.autoUpdate && allTestsRun) {
      if (!this.ctx.server.config.configFile) {
        throw new Error(
          'Missing configurationFile. The "coverage.thresholds.autoUpdate" can only be enabled when configuration file is used.'
        );
      }
      const configFilePath = this.ctx.server.config.configFile;
      const configModule = await this.parseConfigModule(configFilePath);
      await this.updateThresholds({
        thresholds: resolvedThresholds,
        configurationFile: configModule,
        onUpdate: () => writeFileSync(
          configFilePath,
          configModule.generate().code,
          "utf-8"
        )
      });
    }
  }
  /**
   * Constructs collected coverage and users' threshold options into separate sets
   * where each threshold set holds their own coverage maps. Threshold set is either
   * for specific files defined by glob pattern or global for all other files.
   */
  resolveThresholds(coverageMap) {
    const resolvedThresholds = [];
    const files = coverageMap.files();
    const globalCoverageMap = this.createCoverageMap();
    for (const key of Object.keys(this.options.thresholds)) {
      if (key === "perFile" || key === "autoUpdate" || key === "100" || THRESHOLD_KEYS.includes(key)) {
        continue;
      }
      const glob = key;
      const globThresholds = resolveGlobThresholds(this.options.thresholds[glob]);
      const globCoverageMap = this.createCoverageMap();
      const matchingFiles = files.filter(
        (file) => mm.isMatch(relative(this.ctx.config.root, file), glob)
      );
      for (const file of matchingFiles) {
        const fileCoverage = coverageMap.fileCoverageFor(file);
        globCoverageMap.addFileCoverage(fileCoverage);
      }
      resolvedThresholds.push({
        name: glob,
        coverageMap: globCoverageMap,
        thresholds: globThresholds
      });
    }
    for (const file of files) {
      const fileCoverage = coverageMap.fileCoverageFor(file);
      globalCoverageMap.addFileCoverage(fileCoverage);
    }
    resolvedThresholds.unshift({
      name: GLOBAL_THRESHOLDS_KEY,
      coverageMap: globalCoverageMap,
      thresholds: {
        branches: this.options.thresholds?.branches,
        functions: this.options.thresholds?.functions,
        lines: this.options.thresholds?.lines,
        statements: this.options.thresholds?.statements
      }
    });
    return resolvedThresholds;
  }
  /**
   * Check collected coverage against configured thresholds. Sets exit code to 1 when thresholds not reached.
   */
  checkThresholds(allThresholds) {
    for (const { coverageMap, thresholds, name } of allThresholds) {
      if (thresholds.branches === undefined && thresholds.functions === undefined && thresholds.lines === undefined && thresholds.statements === undefined) {
        continue;
      }
      const summaries = this.options.thresholds?.perFile ? coverageMap.files().map((file) => ({
        file,
        summary: coverageMap.fileCoverageFor(file).toSummary()
      })) : [{ file: null, summary: coverageMap.getCoverageSummary() }];
      for (const { summary, file } of summaries) {
        for (const thresholdKey of THRESHOLD_KEYS) {
          const threshold = thresholds[thresholdKey];
          if (threshold === undefined) {
            continue;
          }
          if (threshold >= 0) {
            const coverage = summary.data[thresholdKey].pct;
            if (coverage < threshold) {
              process.exitCode = 1;
              let errorMessage = `ERROR: Coverage for ${thresholdKey} (${coverage}%) does not meet ${name === GLOBAL_THRESHOLDS_KEY ? name : `"${name}"`} threshold (${threshold}%)`;
              if (this.options.thresholds?.perFile && file) {
                errorMessage += ` for ${relative("./", file).replace(/\\/g, "/")}`;
              }
              this.ctx.logger.error(errorMessage);
            }
          } else {
            const uncovered = summary.data[thresholdKey].total - summary.data[thresholdKey].covered;
            const absoluteThreshold = threshold * -1;
            if (uncovered > absoluteThreshold) {
              process.exitCode = 1;
              let errorMessage = `ERROR: Uncovered ${thresholdKey} (${uncovered}) exceed ${name === GLOBAL_THRESHOLDS_KEY ? name : `"${name}"`} threshold (${absoluteThreshold})`;
              if (this.options.thresholds?.perFile && file) {
                errorMessage += ` for ${relative("./", file).replace(/\\/g, "/")}`;
              }
              this.ctx.logger.error(errorMessage);
            }
          }
        }
      }
    }
  }
  /**
   * Check if current coverage is above configured thresholds and bump the thresholds if needed
   */
  async updateThresholds({ thresholds: allThresholds, onUpdate, configurationFile }) {
    let updatedThresholds = false;
    const config = resolveConfig(configurationFile);
    assertConfigurationModule(config);
    for (const { coverageMap, thresholds, name } of allThresholds) {
      const summaries = this.options.thresholds?.perFile ? coverageMap.files().map(
        (file) => coverageMap.fileCoverageFor(file).toSummary()
      ) : [coverageMap.getCoverageSummary()];
      const thresholdsToUpdate = [];
      for (const key of THRESHOLD_KEYS) {
        const threshold = thresholds[key] ?? 100;
        if (threshold >= 0) {
          const actual = Math.min(
            ...summaries.map((summary) => summary[key].pct)
          );
          if (actual > threshold) {
            thresholdsToUpdate.push([key, actual]);
          }
        } else {
          const absoluteThreshold = threshold * -1;
          const actual = Math.max(
            ...summaries.map((summary) => summary[key].total - summary[key].covered)
          );
          if (actual < absoluteThreshold) {
            const updatedThreshold = actual === 0 ? 100 : actual * -1;
            thresholdsToUpdate.push([key, updatedThreshold]);
          }
        }
      }
      if (thresholdsToUpdate.length === 0) {
        continue;
      }
      updatedThresholds = true;
      for (const [threshold, newValue] of thresholdsToUpdate) {
        if (name === GLOBAL_THRESHOLDS_KEY) {
          config.test.coverage.thresholds[threshold] = newValue;
        } else {
          const glob = config.test.coverage.thresholds[name];
          glob[threshold] = newValue;
        }
      }
    }
    if (updatedThresholds) {
      this.ctx.logger.log("Updating thresholds to configuration file. You may want to push with updated coverage thresholds.");
      onUpdate();
    }
  }
  async mergeReports(coverageMaps) {
    const coverageMap = this.createCoverageMap();
    for (const coverage of coverageMaps) {
      coverageMap.merge(coverage);
    }
    await this.generateReports(coverageMap, true);
  }
  hasTerminalReporter(reporters) {
    return reporters.some(
      ([reporter]) => reporter === "text" || reporter === "text-summary" || reporter === "text-lcov" || reporter === "teamcity"
    );
  }
  toSlices(array, size) {
    return array.reduce((chunks, item) => {
      const index = Math.max(0, chunks.length - 1);
      const lastChunk = chunks[index] || [];
      chunks[index] = lastChunk;
      if (lastChunk.length >= size) {
        chunks.push([item]);
      } else {
        lastChunk.push(item);
      }
      return chunks;
    }, []);
  }
  createUncoveredFileTransformer(ctx) {
    const servers = [
      ...ctx.projects.map((project) => ({
        root: project.config.root,
        vitenode: project.vitenode
      })),
      // Check core last as it will match all files anyway
      { root: ctx.config.root, vitenode: ctx.vitenode }
    ];
    return async function transformFile(filename) {
      let lastError;
      for (const { root, vitenode } of servers) {
        if (!filename.startsWith(root)) {
          continue;
        }
        try {
          return await vitenode.transformRequest(filename);
        } catch (error) {
          lastError = error;
        }
      }
      throw lastError;
    };
  }
}
function resolveGlobThresholds(thresholds) {
  if (!thresholds || typeof thresholds !== "object") {
    return {};
  }
  if (100 in thresholds && thresholds[100] === true) {
    return {
      lines: 100,
      branches: 100,
      functions: 100,
      statements: 100
    };
  }
  return {
    lines: "lines" in thresholds && typeof thresholds.lines === "number" ? thresholds.lines : undefined,
    branches: "branches" in thresholds && typeof thresholds.branches === "number" ? thresholds.branches : undefined,
    functions: "functions" in thresholds && typeof thresholds.functions === "number" ? thresholds.functions : undefined,
    statements: "statements" in thresholds && typeof thresholds.statements === "number" ? thresholds.statements : undefined
  };
}
function assertConfigurationModule(config) {
  try {
    if (typeof config.test.coverage.thresholds !== "object") {
      throw new TypeError(
        "Expected config.test.coverage.thresholds to be an object"
      );
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(
      `Unable to parse thresholds from configuration file: ${message}`
    );
  }
}
function resolveConfig(configModule) {
  const mod = configModule.exports.default;
  try {
    if (mod.$type === "object") {
      return mod;
    }
    let config = resolveDefineConfig(mod);
    if (config) {
      return config;
    }
    if (mod.$type === "function-call" && mod.$callee === "mergeConfig") {
      config = resolveMergeConfig(mod);
      if (config) {
        return config;
      }
    }
  } catch (error) {
    throw new Error(error instanceof Error ? error.message : String(error));
  }
  throw new Error(
    "Failed to update coverage thresholds. Configuration file is too complex."
  );
}
function resolveDefineConfig(mod) {
  if (mod.$type === "function-call" && mod.$callee === "defineConfig") {
    if (mod.$args[0].$type === "object") {
      return mod.$args[0];
    }
    if (mod.$args[0].$type === "arrow-function-expression") {
      if (mod.$args[0].$body.$type === "object") {
        return mod.$args[0].$body;
      }
      const config = resolveMergeConfig(mod.$args[0].$body);
      if (config) {
        return config;
      }
    }
  }
}
function resolveMergeConfig(mod) {
  if (mod.$type === "function-call" && mod.$callee === "mergeConfig") {
    for (const arg of mod.$args) {
      const config = resolveDefineConfig(arg);
      if (config) {
        return config;
      }
    }
  }
}

export { BaseCoverageProvider };
