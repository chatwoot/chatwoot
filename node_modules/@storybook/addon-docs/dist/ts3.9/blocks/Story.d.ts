import { FunctionComponent, ReactNode, ElementType, ComponentProps } from 'react';
import { Story as PureStory } from '@storybook/components';
import { StoryId, StoryAnnotations, AnyFramework } from '@storybook/csf';
import { Story as StoryType } from '@storybook/store';
import { DocsContextProps } from './DocsContext';
export declare const storyBlockIdFromId: (storyId: string) => string;
declare type PureStoryProps = ComponentProps<typeof PureStory>;
declare type CommonProps = StoryAnnotations & {
    height?: string;
    inline?: boolean;
};
declare type StoryDefProps = {
    name: string;
    children: ReactNode;
};
declare type StoryRefProps = {
    id?: string;
};
declare type StoryImportProps = {
    name: string;
    story: ElementType;
};
export declare type StoryProps = (StoryDefProps | StoryRefProps | StoryImportProps) & CommonProps;
export declare const lookupStoryId: (storyName: string, { mdxStoryNameToKey, mdxComponentAnnotations }: DocsContextProps) => string;
export declare const getStoryId: (props: StoryProps, context: DocsContextProps) => StoryId;
export declare const getStoryProps: <TFramework extends AnyFramework>({ height, inline }: StoryProps, story: StoryType<TFramework>, context: DocsContextProps<TFramework>, onStoryFnCalled: () => void) => PureStoryProps;
declare const Story: FunctionComponent<StoryProps>;
export { Story };
