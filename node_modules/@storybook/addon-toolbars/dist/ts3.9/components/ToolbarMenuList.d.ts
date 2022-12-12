import { FC } from 'react';
import { WithKeyboardCycleProps } from '../hoc/withKeyboardCycle';
import { ToolbarMenuProps } from '../types';
declare type ToolbarMenuListProps = ToolbarMenuProps & WithKeyboardCycleProps;
export declare const ToolbarMenuList: FC<ToolbarMenuListProps>;
export {};
