import * as React from 'react';
declare type TextareaProps = React.TextareaHTMLAttributes<HTMLTextAreaElement>;
declare type Style = Pick<NonNullable<TextareaProps['style']>, Exclude<keyof NonNullable<TextareaProps['style']>, 'maxHeight' | 'minHeight'>> & {
    height?: number;
};
export declare type TextareaHeightChangeMeta = {
    rowHeight: number;
};
export interface TextareaAutosizeProps extends Pick<TextareaProps, Exclude<keyof TextareaProps, 'style'>> {
    maxRows?: number;
    minRows?: number;
    onHeightChange?: (height: number, meta: TextareaHeightChangeMeta) => void;
    cacheMeasurements?: boolean;
    style?: Style;
}
declare const _default: React.ForwardRefExoticComponent<TextareaAutosizeProps & React.RefAttributes<HTMLTextAreaElement>>;
export default _default;
