import { FunctionComponent } from 'react';
import { DescriptionProps as PureDescriptionProps } from '@storybook/components';
import { DocsContextProps } from './DocsContext';
import { Component } from './types';
export declare enum DescriptionType {
    INFO = "info",
    NOTES = "notes",
    DOCGEN = "docgen",
    LEGACY_5_2 = "legacy-5.2",
    AUTO = "auto"
}
interface DescriptionProps {
    of?: '.' | Component;
    type?: DescriptionType;
    markdown?: string;
    children?: string;
}
export declare const getDescriptionProps: ({ of, type, markdown, children }: DescriptionProps, { id, storyById }: DocsContextProps<any>) => PureDescriptionProps;
declare const DescriptionContainer: FunctionComponent<DescriptionProps>;
export { DescriptionContainer as Description };
