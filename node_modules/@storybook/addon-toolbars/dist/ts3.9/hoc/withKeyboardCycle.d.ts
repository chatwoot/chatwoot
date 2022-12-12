import React from 'react';
import { ToolbarMenuProps } from '../types';
export declare type WithKeyboardCycleProps = {
    cycleValues?: string[];
};
export declare const withKeyboardCycle: (Component: React.ComponentType<ToolbarMenuProps>) => (props: ToolbarMenuProps) => JSX.Element;
