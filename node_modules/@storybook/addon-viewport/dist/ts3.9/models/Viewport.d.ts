export declare type Styles = ViewportStyles | ((s: ViewportStyles) => ViewportStyles) | null;
export interface Viewport {
    name: string;
    styles: Styles;
    type: 'desktop' | 'mobile' | 'tablet' | 'other';
}
export interface ViewportStyles {
    height: string;
    width: string;
}
export interface ViewportMap {
    [key: string]: Viewport;
}
