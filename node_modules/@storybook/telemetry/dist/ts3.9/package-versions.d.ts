import { Dependency } from './types';
export declare const getActualPackageVersions: (packages: Record<string, Partial<Dependency>>) => Promise<{
    name: string;
    version: any;
}[]>;
export declare const getActualPackageVersion: (packageName: string) => Promise<{
    name: string;
    version: any;
}>;
