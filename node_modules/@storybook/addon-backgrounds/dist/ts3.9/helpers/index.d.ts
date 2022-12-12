import { Background } from '../types';
export declare const isReduceMotionEnabled: () => any;
export declare const getBackgroundColorByName: (currentSelectedValue: string, backgrounds: Background[], defaultName: string) => string;
export declare const clearStyles: (selector: string | string[]) => void;
export declare const addGridStyle: (selector: string, css: string) => void;
export declare const addBackgroundStyle: (selector: string, css: string, storyId: string) => void;
