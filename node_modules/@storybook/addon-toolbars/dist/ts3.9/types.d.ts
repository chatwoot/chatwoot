import type { IconsProps } from '@storybook/components';
import type { ArgType } from '@storybook/api';
export declare type ToolbarShortcutType = 'next' | 'previous' | 'reset';
export declare type ToolbarItemType = 'item' | 'reset';
export interface ToolbarShortcutConfig {
    label: string;
    keys: string[];
}
export declare type ToolbarShortcuts = Record<ToolbarShortcutType, ToolbarShortcutConfig>;
export interface ToolbarItem {
    value?: string;
    icon?: IconsProps['icon'];
    left?: string;
    right?: string;
    title?: string;
    hideIcon?: boolean;
    type?: ToolbarItemType;
}
export interface NormalizedToolbarConfig {
    /** The label to show for this toolbar item */
    title?: string;
    /** Choose an icon to show for this toolbar item */
    icon?: IconsProps['icon'];
    /** Set to true to prevent default update of icon to match any present selected items icon */
    preventDynamicIcon?: boolean;
    items: ToolbarItem[];
    shortcuts?: ToolbarShortcuts;
    /** @deprecated "name" no longer dual purposes as title - use "title" if a title is wanted */
    showName?: boolean;
    /** Change title based on selected value */
    dynamicTitle?: boolean;
}
export declare type NormalizedToolbarArgType = ArgType & {
    toolbar: NormalizedToolbarConfig;
};
export declare type ToolbarConfig = NormalizedToolbarConfig & {
    items: string[] | ToolbarItem[];
};
export declare type ToolbarArgType = ArgType & {
    toolbar: ToolbarConfig;
};
export declare type ToolbarMenuProps = NormalizedToolbarArgType & {
    id: string;
};
