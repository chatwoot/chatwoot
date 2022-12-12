import { PackageJson } from '../types';
interface StorybookInfo {
    framework: string;
    version: string;
    frameworkPackage: string;
    configDir?: string;
    mainConfig?: string;
    previewConfig?: string;
    managerConfig?: string;
}
export declare const getStorybookInfo: (packageJson: PackageJson) => StorybookInfo;
export {};
