import { Types } from '@storybook/addons';
import { FunctionComponent } from 'react';
export declare class Provider {
    getElements(_type: Types): void;
    handleAPI(_api: unknown): void;
    getConfig(): {};
}
export declare const Root: FunctionComponent<RootProps>;
export default function renderStorybookUI(domNode: HTMLElement, provider: Provider): void;
export interface RootProps {
    provider: Provider;
    history?: History;
}
export {};