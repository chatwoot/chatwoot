import { API } from '@storybook/api';
import { ToolbarShortcutConfig } from '../types';
interface Shortcuts {
    next: ToolbarShortcutConfig & {
        action: () => void;
    };
    previous: ToolbarShortcutConfig & {
        action: () => void;
    };
    reset: ToolbarShortcutConfig & {
        action: () => void;
    };
}
export declare const registerShortcuts: (api: API, id: string, shortcuts: Shortcuts) => Promise<void>;
export {};
