import { AnyFramework, ComponentTitle } from '@storybook/csf';
import { ModuleExports, CSFFile, Path } from '../types';
export declare function processCSFFile<TFramework extends AnyFramework>(moduleExports: ModuleExports, importPath: Path, title: ComponentTitle): CSFFile<TFramework>;
