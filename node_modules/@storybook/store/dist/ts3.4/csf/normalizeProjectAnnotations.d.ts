import { AnyFramework, ProjectAnnotations } from '@storybook/csf';
import { NormalizedProjectAnnotations } from '../types';
export declare function normalizeProjectAnnotations<TFramework extends AnyFramework>({ argTypes, globalTypes, argTypesEnhancers, ...annotations }: ProjectAnnotations<TFramework>): NormalizedProjectAnnotations<TFramework>;
