import { FC } from 'react';
import { PreviewProps as PurePreviewProps } from '@storybook/components';
import { SourceState } from './Source';
export { SourceState };
declare type CanvasProps = PurePreviewProps & {
    withSource?: SourceState;
    mdxSource?: string;
};
export declare const Canvas: FC<CanvasProps>;
