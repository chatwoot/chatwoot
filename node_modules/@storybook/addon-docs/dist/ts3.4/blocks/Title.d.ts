import { FunctionComponent } from 'react';
import { DocsContextProps } from './DocsContext';
interface TitleProps {
    children?: JSX.Element | string;
}
export declare const extractTitle: ({ title }: DocsContextProps) => string;
export declare const Title: FunctionComponent<TitleProps>;
export {};
