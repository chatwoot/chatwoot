import { FC } from 'react';
import { DocsContextProps } from './DocsContext';
export declare const assertIsFn: (val: any) => any;
export declare const AddContext: FC<DocsContextProps>;
interface CodeOrSourceMdxProps {
    className?: string;
}
export declare const CodeOrSourceMdx: FC<CodeOrSourceMdxProps>;
interface AnchorMdxProps {
    href: string;
    target: string;
}
export declare const AnchorMdx: FC<AnchorMdxProps>;
interface HeaderMdxProps {
    as: string;
    id: string;
}
export declare const HeaderMdx: FC<HeaderMdxProps>;
export declare const HeadersMdx: {};
export {};
