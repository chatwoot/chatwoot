import { ReactNode } from 'react';
import { ToolbarItem } from '../types';
interface ListItem {
    id: string;
    left?: ReactNode;
    title?: ReactNode;
    right?: ReactNode;
    active?: boolean;
    onClick?: () => void;
}
declare type ToolbarMenuListItemProps = {
    currentValue: string;
    onClick: () => void;
} & ToolbarItem;
export declare const ToolbarMenuListItem: ({ left, right, title, value, icon, hideIcon, onClick, currentValue, }: ToolbarMenuListItemProps) => ListItem;
export {};
