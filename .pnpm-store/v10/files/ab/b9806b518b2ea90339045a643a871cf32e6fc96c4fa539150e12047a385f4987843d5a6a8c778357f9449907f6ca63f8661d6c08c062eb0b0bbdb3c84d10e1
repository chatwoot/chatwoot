import { V8CoverageProvider } from './provider.js';
import { Profiler } from 'node:inspector';
import 'magicast';
import 'istanbul-lib-coverage';
import 'vitest/node';
import 'test-exclude';
import 'vitest/coverage';

declare const _default: {
    startCoverage({ isolate }: {
        isolate: boolean;
    }): void;
    takeCoverage(): Promise<{
        result: Profiler.ScriptCoverage[];
    }>;
    stopCoverage({ isolate }: {
        isolate: boolean;
    }): void;
    getProvider(): Promise<V8CoverageProvider>;
};

export { _default as default };
