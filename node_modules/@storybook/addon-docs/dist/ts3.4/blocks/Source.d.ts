import { ComponentProps, FC } from 'react';
import { Source as PureSource } from '@storybook/components';
import { DocsContextProps } from './DocsContext';
import { SourceContextProps } from './SourceContainer';
export declare enum SourceState {
    OPEN = "open",
    CLOSED = "closed",
    NONE = "none"
}
interface CommonProps {
    language?: string;
    dark?: boolean;
    format?: PureSourceProps['format'];
    code?: string;
}
declare type SingleSourceProps = {
    id: string;
} & CommonProps;
declare type MultiSourceProps = {
    ids: string[];
} & CommonProps;
declare type CodeProps = {
    code: string;
} & CommonProps;
declare type NoneProps = CommonProps;
declare type SourceProps = SingleSourceProps | MultiSourceProps | CodeProps | NoneProps;
declare type SourceStateProps = {
    state: SourceState;
};
declare type PureSourceProps = ComponentProps<typeof PureSource>;
export declare const getSourceProps: (props: SourceProps, docsContext: DocsContextProps<any>, sourceContext: SourceContextProps) => PureSourceProps & SourceStateProps;
/**
 * Story source doc block renders source code if provided,
 * or the source for a story if `storyId` is provided, or
 * the source for the current story if nothing is provided.
 */
export declare const Source: FC<PureSourceProps>;
export {};
