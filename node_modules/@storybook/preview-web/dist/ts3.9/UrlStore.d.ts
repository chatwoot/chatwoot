import type { SelectionSpecifier, Selection } from '@storybook/store';
import qs from 'qs';
export declare function pathToId(path: string): string;
export declare const setPath: (selection?: Selection) => void;
export declare const getSelectionSpecifierFromPath: () => SelectionSpecifier;
export declare class UrlStore {
    selectionSpecifier: SelectionSpecifier;
    selection: Selection;
    constructor();
    setSelection(selection: Selection): void;
    setQueryParams(queryParams: qs.ParsedQs): void;
}
