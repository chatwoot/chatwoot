import { Stats } from 'webpack';
export declare function outputStats(directory: string, previewStats?: any, managerStats?: any): Promise<void>;
export declare const writeStats: (directory: string, name: string, stats: Stats) => Promise<string>;
