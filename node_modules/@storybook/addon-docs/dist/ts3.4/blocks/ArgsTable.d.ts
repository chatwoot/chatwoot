import { FC } from 'react';
import { SortType } from '@storybook/components';
import { PropDescriptor } from '@storybook/store';
import { StrictArgTypes } from '@storybook/csf';
import { DocsContextProps } from './DocsContext';
import { Component } from './types';
interface BaseProps {
    include?: PropDescriptor;
    exclude?: PropDescriptor;
    sort?: SortType;
}
declare type OfProps = BaseProps & {
    of: '.' | '^' | Component;
};
declare type ComponentsProps = BaseProps & {
    components: {
        [label: string]: Component;
    };
};
declare type StoryProps = BaseProps & {
    story: '.' | '^' | string;
    showComponent?: boolean;
};
declare type ArgsTableProps = BaseProps | OfProps | ComponentsProps | StoryProps;
export declare const extractComponentArgTypes: (component: Component, { id, storyById }: DocsContextProps, include?: PropDescriptor, exclude?: PropDescriptor) => StrictArgTypes;
export declare const getComponent: (props: ArgsTableProps, { id, storyById }: DocsContextProps) => Component;
export declare const StoryTable: FC<StoryProps & {
    component: Component;
    subcomponents: Record<string, Component>;
}>;
export declare const ComponentsTable: FC<ComponentsProps>;
export declare const ArgsTable: FC<ArgsTableProps>;
export {};
