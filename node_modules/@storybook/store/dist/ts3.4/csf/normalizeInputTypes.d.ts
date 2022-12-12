import { ArgTypes, GlobalTypes, InputType, StrictArgTypes, StrictGlobalTypes, StrictInputType } from '@storybook/csf';
export declare const normalizeInputType: (inputType: InputType, key: string) => StrictInputType;
export declare const normalizeInputTypes: (inputTypes: ArgTypes | GlobalTypes) => StrictArgTypes | StrictGlobalTypes;
