import { AnyFramework } from '@storybook/csf';
import { ModuleExports, WebProjectAnnotations } from '../types';
export declare function getField<TFieldType = any>(moduleExportList: ModuleExports[], field: string): TFieldType | TFieldType[];
export declare function getArrayField<TFieldType = any>(moduleExportList: ModuleExports[], field: string): TFieldType[];
export declare function getObjectField<TFieldType = Record<string, any>>(moduleExportList: ModuleExports[], field: string): TFieldType;
export declare function getSingletonField<TFieldType = any>(moduleExportList: ModuleExports[], field: string): TFieldType;
export declare function composeConfigs<TFramework extends AnyFramework>(moduleExportList: ModuleExports[]): WebProjectAnnotations<TFramework>;
