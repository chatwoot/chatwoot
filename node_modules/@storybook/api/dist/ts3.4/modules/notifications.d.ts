import { ReactNode } from 'react';
import { ModuleFn } from '../index';
export interface Notification {
    id: string;
    link: string;
    content: {
        headline: string;
        subHeadline?: string | ReactNode;
    };
    icon?: {
        name: string;
        color?: string;
    };
    onClear?: () => void;
}
export interface SubState {
    notifications: Notification[];
}
export interface SubAPI {
    addNotification: (notification: Notification) => void;
    clearNotification: (id: string) => void;
}
export declare const init: ModuleFn;
