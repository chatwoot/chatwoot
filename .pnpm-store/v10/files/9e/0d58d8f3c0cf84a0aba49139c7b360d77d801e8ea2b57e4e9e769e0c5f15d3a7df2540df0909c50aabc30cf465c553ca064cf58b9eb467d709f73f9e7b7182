import * as magicast from 'magicast';
import { CoverageMap } from 'istanbul-lib-coverage';
import { ResolvedCoverageOptions, CoverageProvider, Vitest, ReportContext } from 'vitest/node';
import TestExclude from 'test-exclude';
import { BaseCoverageProvider } from 'vitest/coverage';

declare class V8CoverageProvider extends BaseCoverageProvider<ResolvedCoverageOptions<'v8'>> implements CoverageProvider {
    name: "v8";
    version: string;
    testExclude: InstanceType<typeof TestExclude>;
    initialize(ctx: Vitest): void;
    createCoverageMap(): CoverageMap;
    generateCoverage({ allTestsRun }: ReportContext): Promise<CoverageMap>;
    generateReports(coverageMap: CoverageMap, allTestsRun?: boolean): Promise<void>;
    parseConfigModule(configFilePath: string): Promise<magicast.ProxifiedModule<any>>;
    private getUntestedFiles;
    private getSources;
    private convertCoverage;
}

export { V8CoverageProvider };
