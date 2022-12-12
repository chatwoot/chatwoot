import type { StorybookConfig, TypescriptOptions } from '@storybook/core-common';
import type { PM } from 'detect-package-manager';
import type { MonorepoType } from './get-monorepo-type';
export declare type EventType = 'start' | 'build' | 'upgrade' | 'init' | 'error-build' | 'error-dev' | 'error-metadata';
export interface Dependency {
    version: string;
}
export interface StorybookAddon extends Dependency {
    options: any;
}
export declare type StorybookMetadata = {
    storybookVersion: string;
    generatedAt?: number;
    language: 'typescript' | 'javascript';
    framework: {
        name: string;
        options?: any;
    };
    builder?: {
        name: string;
        options?: Record<string, any>;
    };
    monorepo?: MonorepoType;
    packageManager?: {
        type: PM;
        version: string;
    };
    typescriptOptions?: Partial<TypescriptOptions>;
    addons?: Record<string, StorybookAddon>;
    storybookPackages?: Record<string, Dependency>;
    metaFramework?: {
        name: string;
        packageName: string;
        version: string;
    };
    hasStorybookEslint?: boolean;
    hasStaticDirs?: boolean;
    hasCustomWebpack?: boolean;
    hasCustomBabel?: boolean;
    features?: StorybookConfig['features'];
    refCount?: number;
};
export interface Payload {
    [key: string]: any;
}
export interface Options {
    retryDelay: number;
    immediate: boolean;
    configDir?: string;
    enableCrashReports?: boolean;
}
export interface TelemetryData {
    eventType: EventType;
    payload: Payload;
    metadata?: StorybookMetadata;
}
