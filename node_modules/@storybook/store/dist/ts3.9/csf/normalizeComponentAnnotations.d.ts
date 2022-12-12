import type { AnyFramework } from '@storybook/csf';
import type { ModuleExports, NormalizedComponentAnnotations } from '../types';
export declare function normalizeComponentAnnotations<TFramework extends AnyFramework>(defaultExport: ModuleExports['default'], title?: string, importPath?: string): NormalizedComponentAnnotations<TFramework>;
