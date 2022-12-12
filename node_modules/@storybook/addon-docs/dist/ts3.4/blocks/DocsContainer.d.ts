import { FunctionComponent } from 'react';
import { AnyFramework } from '@storybook/csf';
import { DocsContextProps } from './DocsContext';
export interface DocsContainerProps<TFramework extends AnyFramework = AnyFramework> {
    context: DocsContextProps<TFramework>;
}
export declare const DocsContainer: FunctionComponent<DocsContainerProps>;
