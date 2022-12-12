export declare const CURRENT_SELECTION = ".";
export declare const PRIMARY_STORY = "^";
export declare type Component = any;
export interface StoryData {
    id?: string;
    kind?: string;
    name?: string;
    parameters?: any;
}
export declare type DocsStoryProps = StoryData & {
    expanded?: boolean;
    withToolbar?: boolean;
};
