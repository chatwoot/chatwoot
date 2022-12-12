export declare enum PropertyTypes {
    TEXT = "text",
    NUMBER = "number",
    BOOLEAN = "boolean",
    OPTIONS = "options",
    DATE = "date",
    COLOR = "color",
    BUTTON = "button",
    OBJECT = "object",
    ARRAY = "array",
    FILES = "files"
}
export interface StoryPropertyBase<T> {
    type: PropertyTypes;
    label?: string;
    value?: T;
    hideLabel?: boolean;
    hidden?: boolean;
    groupId?: string;
    order?: number;
}
export interface StoryPropertyText extends StoryPropertyBase<string> {
    type: PropertyTypes.TEXT;
    placeholder?: string;
    maxRows?: number;
}
export interface StoryPropertyBoolean extends StoryPropertyBase<boolean> {
    type: PropertyTypes.BOOLEAN;
}
export interface StoryPropertyColor extends StoryPropertyBase<string> {
    type: PropertyTypes.COLOR;
}
export interface StoryPropertyDate extends StoryPropertyBase<Date> {
    type: PropertyTypes.DATE;
    datePicker?: boolean;
    timePicker?: boolean;
}
export interface StoryPropertyFiles extends StoryPropertyBase<string[]> {
    type: PropertyTypes.FILES;
    accept?: string;
}
export interface StoryPropertyArray extends StoryPropertyBase<string[]> {
    type: PropertyTypes.ARRAY;
    separator?: string;
}
export interface StoryPropertyObject extends StoryPropertyBase<object> {
    type: PropertyTypes.OBJECT;
}
export interface StoryPropertyButton extends StoryPropertyBase<void> {
    type: PropertyTypes.BUTTON;
    onClick?: (prop: StoryPropertyButton) => void;
}
export declare type OptionsValueType<T = unknown> = T | string | number | string[] | number[] | {
    label: string;
    value: any;
};
export declare type OptionsListType<T = unknown> = {
    [key: string]: T;
} | OptionsValueType<T>[];
export interface StoryPropertyOptions<T = unknown> extends StoryPropertyBase<OptionsValueType<T>> {
    type: PropertyTypes.OPTIONS;
    options: OptionsListType<T>;
    display?: 'select' | 'multi-select' | 'radio' | 'inline-radio' | 'check' | 'inline-check';
}
export interface StoryPropertyNumber extends StoryPropertyBase<number> {
    type: PropertyTypes.NUMBER;
    range?: boolean;
    min?: number;
    max?: number;
    step?: number;
}
export declare type StoryProperty = StoryPropertyText | StoryPropertyBoolean | StoryPropertyColor | StoryPropertyDate | StoryPropertyObject | StoryPropertyButton | StoryPropertyOptions | StoryPropertyNumber | StoryPropertyArray | StoryPropertyFiles;
export interface StoryProperties {
    [name: string]: StoryProperty;
}
