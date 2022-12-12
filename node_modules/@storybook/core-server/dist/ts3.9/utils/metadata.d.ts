import { Router } from 'express';
export declare function extractStorybookMetadata(outputFile: string, configDir: string): Promise<void>;
export declare function useStorybookMetadata(router: Router, configDir?: string): void;
