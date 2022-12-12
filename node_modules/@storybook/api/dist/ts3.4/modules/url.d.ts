import { NavigateOptions } from '@storybook/router';
import { ModuleFn } from '../index';
export interface SubState {
    customQueryParams: QueryParams;
}
export interface QueryParams {
    [key: string]: string | null;
}
export interface SubAPI {
    navigateUrl: (url: string, options: NavigateOptions) => void;
    getQueryParam: (key: string) => string | undefined;
    getUrlState: () => {
        queryParams: QueryParams;
        path: string;
        viewMode?: string;
        storyId?: string;
        url: string;
    };
    setQueryParams: (input: QueryParams) => void;
}
export declare const init: ModuleFn;
