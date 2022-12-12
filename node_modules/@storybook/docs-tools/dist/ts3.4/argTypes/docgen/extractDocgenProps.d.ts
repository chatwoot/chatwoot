import { Component } from '../types';
import { ExtractedJsDoc } from '../jsdocParser';
import { PropDef, DocgenInfo, TypeSystem } from './types';
export interface ExtractedProp {
    propDef: PropDef;
    docgenInfo: DocgenInfo;
    jsDocTags: ExtractedJsDoc;
    typeSystem: TypeSystem;
}
export declare type ExtractProps = (component: Component, section: string) => ExtractedProp[];
export declare const extractComponentSectionArray: (docgenSection: any) => any;
export declare const extractComponentSectionObject: (docgenSection: any) => ExtractedProp[];
export declare const extractComponentProps: ExtractProps;
export declare function extractComponentDescription(component?: Component): string;
