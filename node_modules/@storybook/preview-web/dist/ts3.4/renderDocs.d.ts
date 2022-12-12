import { AnyFramework } from '@storybook/csf';
import { Story } from '@storybook/store';
import { DocsContextProps } from './types';
export declare function renderDocs<TFramework extends AnyFramework>(story: Story<TFramework>, docsContext: DocsContextProps<TFramework>, element: HTMLElement, callback: () => void): Promise<void>;
export declare function unmountDocs(element: HTMLElement): void;
