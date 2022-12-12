import { FC, Context } from 'react';
import type { SyntaxHighlighterFormatTypes } from '@storybook/components';
import type { StoryId } from '@storybook/api';
export interface SourceItem {
    code: string;
    format: SyntaxHighlighterFormatTypes;
}
export declare type StorySources = Record<StoryId, SourceItem>;
export interface SourceContextProps {
    sources: StorySources;
    setSource?: (id: StoryId, item: SourceItem) => void;
}
export declare const SourceContext: Context<SourceContextProps>;
export declare const SourceContainer: FC<{}>;
