import { FC } from 'react';
import { IconsProps } from '@storybook/components';
interface ToolbarMenuButtonProps {
    active: boolean;
    title: string;
    icon: IconsProps['icon'] | '';
    description: string;
    onClick?: () => void;
}
export declare const ToolbarMenuButton: FC<ToolbarMenuButtonProps>;
export {};
