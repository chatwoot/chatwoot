import { AnyFramework } from '@storybook/csf';
import { ModuleExports, NormalizedComponentAnnotations } from '../types';
export declare function normalizeComponentAnnotations<TFramework extends AnyFramework>(defaultExport: ModuleExports['default'], title?: string, importPath?: string): NormalizedComponentAnnotations<TFramework>;
