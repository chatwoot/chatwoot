import { Analytics } from '../../core/analytics';
import { LegacyIntegrationConfiguration } from '../../browser';
import { Context } from '../../core/context';
import { LegacyIntegration, ClassicIntegrationSource } from './types';
export declare function resolveIntegrationNameFromSource(integrationSource: ClassicIntegrationSource): string;
export declare function buildIntegration(integrationSource: ClassicIntegrationSource, integrationSettings: {
    [key: string]: any;
}, analyticsInstance: Analytics): LegacyIntegration;
export declare function loadIntegration(ctx: Context, name: string, version: string, obfuscate?: boolean): Promise<ClassicIntegrationSource>;
export declare function unloadIntegration(name: string, version: string, obfuscate?: boolean): Promise<void>;
export declare function resolveVersion(settings?: LegacyIntegrationConfiguration): string;
//# sourceMappingURL=loader.d.ts.map