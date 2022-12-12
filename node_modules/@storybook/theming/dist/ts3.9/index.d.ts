import * as emotionReact from "./_modules/@emotion-react-types-index";
import { Interpolation, Keyframes, SerializedStyles } from "./_modules/@emotion-react-types-index";
declare const animation: {
    readonly rotate360: Keyframes;
    readonly glow: Keyframes;
    readonly float: Keyframes;
    readonly jiggle: Keyframes;
    readonly inlineGlow: SerializedStyles;
    readonly hoverable: SerializedStyles;
};
declare const darkenColor: (color: string) => string;
declare const easing: {
    rubber: string;
};
declare const lightenColor: (color: string) => string;
export declare const Global: (props: {
    styles: emotionReact.Interpolation<Theme>;
}) => React.ReactElement;
export declare const background: {
    app: string;
    bar: string;
    content: string;
    gridCellSize: number;
    hoverable: string;
    positive: string;
    negative: string;
    warning: string;
    critical: string;
};
export declare const color: {
    primary: string;
    secondary: string;
    tertiary: string;
    ancillary: string;
    orange: string;
    gold: string;
    green: string;
    seafoam: string;
    purple: string;
    ultraviolet: string;
    lightest: string;
    lighter: string;
    light: string;
    mediumlight: string;
    medium: string;
    mediumdark: string;
    dark: string;
    darker: string;
    darkest: string;
    border: string;
    positive: string;
    negative: string;
    warning: string;
    critical: string;
    defaultText: string;
    inverseText: string;
};
export declare const convert: (inherit?: ThemeVars) => Theme;
export declare const create: (vars?: ThemeVars, rest?: Rest) => ThemeVars;
export declare const createGlobal: ({ color, background, typography, }: {
    color: Color;
    background: Background;
    typography: Typography;
}) => Return;
export declare const createReset: ({ typography }: {
    typography: Typography;
}) => Return;
export declare const ensure: (input: ThemeVars) => Theme;
export declare const ignoreSsrWarning = "/* emotion-disable-server-rendering-unsafe-selector-warning-please-do-not-use-this-the-warning-exists-for-a-reason */";
export declare const styled: CreateStyled<Theme>;
export declare const themes: {
    light: ThemeVars;
    dark: ThemeVars;
    normal: ThemeVars;
};
export declare const typography: {
    fonts: {
        base: string;
        mono: string;
    };
    weight: {
        regular: number;
        bold: number;
        black: number;
    };
    size: {
        s1: number;
        s2: number;
        s3: number;
        m1: number;
        m2: number;
        m3: number;
        l1: number;
        l2: number;
        l3: number;
        code: number;
    };
};
export declare const useTheme: <TTheme = Theme>() => TTheme;
export declare const withTheme: <C extends import("react").ComponentType<any>>(component: C) => import("react").FC<AddOptionalTo<JSX.LibraryManagedAttributes<C, import("react").ComponentPropsWithRef<C>>, "theme">>;
export declare type AddOptionalTo<T, U> = DistributiveOmit<T, U> & Partial<Pick<T, Extract<keyof T, U>>>;
export declare type Animation = typeof animation;
export declare type Background = typeof background;
export declare type Color = typeof color;
export declare type CreateStyledComponentBase<InnerProps, ExtraProps, StyledInstanceTheme extends object> = object extends StyledInstanceTheme ? CreateStyledComponentBaseThemeless<InnerProps, ExtraProps> : CreateStyledComponentBaseThemed<InnerProps, ExtraProps, StyledInstanceTheme>;
export declare type CreateStyledComponentExtrinsic<Tag extends React.ComponentType<any>, ExtraProps, Theme extends object> = CreateStyledComponentBase<PropsOf<Tag>, ExtraProps, Theme>;
export declare type CreateStyledComponentIntrinsic<Tag extends keyof JSXInEl, ExtraProps, Theme extends object> = CreateStyledComponentBase<JSXInEl[Tag], ExtraProps, Theme>;
export declare type DistributiveOmit<T, U> = T extends any ? Pick<T, Exclude<keyof T, U>> : never;
export declare type Easing = typeof easing;
export declare type JSXInEl = JSX.IntrinsicElements;
export declare type Overwrapped<T, U> = Pick<T, Extract<keyof T, keyof U>>;
export declare type PropsOf<C extends keyof JSX.IntrinsicElements | React.JSXElementConstructor<any>> = JSX.LibraryManagedAttributes<C, React.ComponentPropsWithRef<C>>;
export declare type ReactClassPropKeys = keyof React.ClassAttributes<any>;
export declare type TextSize = number | string;
export declare type Typography = typeof typography;
export declare type Value = string | number;
export declare type WithTheme<P, T> = P extends {
    theme: infer Theme;
} ? P & {
    theme: Exclude<Theme, undefined>;
} : P & {
    theme: T;
};
export interface BaseCreateStyled<Theme extends object = any> {
    <Tag extends React.ComponentType<any>, ExtraProps = {}>(tag: Tag, options?: StyledOptions): CreateStyledComponentExtrinsic<Tag, ExtraProps, Theme>;
    <Tag extends keyof JSXInEl, ExtraProps = {}>(tag: Tag, options?: StyledOptions): CreateStyledComponentIntrinsic<Tag, ExtraProps, Theme>;
}
export interface Brand {
    title: string | undefined;
    url: string | null | undefined;
    image: string | null | undefined;
    target: string | null | undefined;
}
export interface ComponentSelector {
    __emotion_styles: any;
}
export interface CreateStyled<Theme extends object = any> extends BaseCreateStyled<Theme>, StyledTags<Theme> {
}
export interface CreateStyledComponentBaseThemed<InnerProps, ExtraProps, StyledInstanceTheme extends object> {
    <StyleProps extends DistributiveOmit<Overwrapped<InnerProps, StyleProps>, ReactClassPropKeys> = DistributiveOmit<InnerProps & ExtraProps, ReactClassPropKeys>>(...styles: Array<Interpolation<WithTheme<StyleProps, StyledInstanceTheme>>>): StyledComponent<InnerProps, StyleProps, StyledInstanceTheme>;
    <StyleProps extends DistributiveOmit<Overwrapped<InnerProps, StyleProps>, ReactClassPropKeys> = DistributiveOmit<InnerProps & ExtraProps, ReactClassPropKeys>>(template: TemplateStringsArray, ...styles: Array<Interpolation<WithTheme<StyleProps, StyledInstanceTheme>>>): StyledComponent<InnerProps, StyleProps, StyledInstanceTheme>;
}
export interface CreateStyledComponentBaseThemeless<InnerProps, ExtraProps> {
    <StyleProps extends DistributiveOmit<Overwrapped<InnerProps, StyleProps>, ReactClassPropKeys> = DistributiveOmit<InnerProps & ExtraProps, ReactClassPropKeys>, Theme extends object = object>(...styles: Array<Interpolation<WithTheme<StyleProps, Theme>>>): StyledComponent<InnerProps, StyleProps, Theme>;
    <StyleProps extends DistributiveOmit<Overwrapped<InnerProps, StyleProps>, ReactClassPropKeys> = DistributiveOmit<InnerProps & ExtraProps, ReactClassPropKeys>, Theme extends object = object>(template: TemplateStringsArray, ...styles: Array<Interpolation<WithTheme<StyleProps, Theme>>>): StyledComponent<InnerProps, StyleProps, Theme>;
}
export interface Rest {
    [key: string]: any;
}
export interface Return {
    [key: string]: {
        [key: string]: Value;
    };
}
export interface StyledComponent<InnerProps, StyleProps, Theme extends object> extends React.FC<InnerProps & DistributiveOmit<StyleProps, "theme"> & {
    theme?: Theme;
}>, ComponentSelector {
    /**
     * @desc this method is type-unsafe
     */
    withComponent<NewTag extends keyof JSXInEl>(tag: NewTag): StyledComponent<JSXInEl[NewTag], StyleProps, Theme>;
    withComponent<Tag extends React.ComponentType<any>>(tag: Tag): StyledComponent<PropsOf<Tag>, StyleProps, Theme>;
}
export interface StyledOptions {
    label?: string;
    shouldForwardProp?(propName: string): boolean;
    target?: string;
}
export interface StyledTags<Theme extends object> {
    /**
     * @desc
     * HTML tags
     */
    a: CreateStyledComponentIntrinsic<"a", {}, Theme>;
    abbr: CreateStyledComponentIntrinsic<"abbr", {}, Theme>;
    address: CreateStyledComponentIntrinsic<"address", {}, Theme>;
    area: CreateStyledComponentIntrinsic<"area", {}, Theme>;
    article: CreateStyledComponentIntrinsic<"article", {}, Theme>;
    aside: CreateStyledComponentIntrinsic<"aside", {}, Theme>;
    audio: CreateStyledComponentIntrinsic<"audio", {}, Theme>;
    b: CreateStyledComponentIntrinsic<"b", {}, Theme>;
    base: CreateStyledComponentIntrinsic<"base", {}, Theme>;
    bdi: CreateStyledComponentIntrinsic<"bdi", {}, Theme>;
    bdo: CreateStyledComponentIntrinsic<"bdo", {}, Theme>;
    big: CreateStyledComponentIntrinsic<"big", {}, Theme>;
    blockquote: CreateStyledComponentIntrinsic<"blockquote", {}, Theme>;
    body: CreateStyledComponentIntrinsic<"body", {}, Theme>;
    br: CreateStyledComponentIntrinsic<"br", {}, Theme>;
    button: CreateStyledComponentIntrinsic<"button", {}, Theme>;
    canvas: CreateStyledComponentIntrinsic<"canvas", {}, Theme>;
    caption: CreateStyledComponentIntrinsic<"caption", {}, Theme>;
    cite: CreateStyledComponentIntrinsic<"cite", {}, Theme>;
    code: CreateStyledComponentIntrinsic<"code", {}, Theme>;
    col: CreateStyledComponentIntrinsic<"col", {}, Theme>;
    colgroup: CreateStyledComponentIntrinsic<"colgroup", {}, Theme>;
    data: CreateStyledComponentIntrinsic<"data", {}, Theme>;
    datalist: CreateStyledComponentIntrinsic<"datalist", {}, Theme>;
    dd: CreateStyledComponentIntrinsic<"dd", {}, Theme>;
    del: CreateStyledComponentIntrinsic<"del", {}, Theme>;
    details: CreateStyledComponentIntrinsic<"details", {}, Theme>;
    dfn: CreateStyledComponentIntrinsic<"dfn", {}, Theme>;
    dialog: CreateStyledComponentIntrinsic<"dialog", {}, Theme>;
    div: CreateStyledComponentIntrinsic<"div", {}, Theme>;
    dl: CreateStyledComponentIntrinsic<"dl", {}, Theme>;
    dt: CreateStyledComponentIntrinsic<"dt", {}, Theme>;
    em: CreateStyledComponentIntrinsic<"em", {}, Theme>;
    embed: CreateStyledComponentIntrinsic<"embed", {}, Theme>;
    fieldset: CreateStyledComponentIntrinsic<"fieldset", {}, Theme>;
    figcaption: CreateStyledComponentIntrinsic<"figcaption", {}, Theme>;
    figure: CreateStyledComponentIntrinsic<"figure", {}, Theme>;
    footer: CreateStyledComponentIntrinsic<"footer", {}, Theme>;
    form: CreateStyledComponentIntrinsic<"form", {}, Theme>;
    h1: CreateStyledComponentIntrinsic<"h1", {}, Theme>;
    h2: CreateStyledComponentIntrinsic<"h2", {}, Theme>;
    h3: CreateStyledComponentIntrinsic<"h3", {}, Theme>;
    h4: CreateStyledComponentIntrinsic<"h4", {}, Theme>;
    h5: CreateStyledComponentIntrinsic<"h5", {}, Theme>;
    h6: CreateStyledComponentIntrinsic<"h6", {}, Theme>;
    head: CreateStyledComponentIntrinsic<"head", {}, Theme>;
    header: CreateStyledComponentIntrinsic<"header", {}, Theme>;
    hgroup: CreateStyledComponentIntrinsic<"hgroup", {}, Theme>;
    hr: CreateStyledComponentIntrinsic<"hr", {}, Theme>;
    html: CreateStyledComponentIntrinsic<"html", {}, Theme>;
    i: CreateStyledComponentIntrinsic<"i", {}, Theme>;
    iframe: CreateStyledComponentIntrinsic<"iframe", {}, Theme>;
    img: CreateStyledComponentIntrinsic<"img", {}, Theme>;
    input: CreateStyledComponentIntrinsic<"input", {}, Theme>;
    ins: CreateStyledComponentIntrinsic<"ins", {}, Theme>;
    kbd: CreateStyledComponentIntrinsic<"kbd", {}, Theme>;
    keygen: CreateStyledComponentIntrinsic<"keygen", {}, Theme>;
    label: CreateStyledComponentIntrinsic<"label", {}, Theme>;
    legend: CreateStyledComponentIntrinsic<"legend", {}, Theme>;
    li: CreateStyledComponentIntrinsic<"li", {}, Theme>;
    link: CreateStyledComponentIntrinsic<"link", {}, Theme>;
    main: CreateStyledComponentIntrinsic<"main", {}, Theme>;
    map: CreateStyledComponentIntrinsic<"map", {}, Theme>;
    mark: CreateStyledComponentIntrinsic<"mark", {}, Theme>;
    /**
     * @desc
     * marquee tag is not supported by @types/react
     */
    menu: CreateStyledComponentIntrinsic<"menu", {}, Theme>;
    menuitem: CreateStyledComponentIntrinsic<"menuitem", {}, Theme>;
    meta: CreateStyledComponentIntrinsic<"meta", {}, Theme>;
    meter: CreateStyledComponentIntrinsic<"meter", {}, Theme>;
    nav: CreateStyledComponentIntrinsic<"nav", {}, Theme>;
    noscript: CreateStyledComponentIntrinsic<"noscript", {}, Theme>;
    object: CreateStyledComponentIntrinsic<"object", {}, Theme>;
    ol: CreateStyledComponentIntrinsic<"ol", {}, Theme>;
    optgroup: CreateStyledComponentIntrinsic<"optgroup", {}, Theme>;
    option: CreateStyledComponentIntrinsic<"option", {}, Theme>;
    output: CreateStyledComponentIntrinsic<"output", {}, Theme>;
    p: CreateStyledComponentIntrinsic<"p", {}, Theme>;
    param: CreateStyledComponentIntrinsic<"param", {}, Theme>;
    picture: CreateStyledComponentIntrinsic<"picture", {}, Theme>;
    pre: CreateStyledComponentIntrinsic<"pre", {}, Theme>;
    progress: CreateStyledComponentIntrinsic<"progress", {}, Theme>;
    q: CreateStyledComponentIntrinsic<"q", {}, Theme>;
    rp: CreateStyledComponentIntrinsic<"rp", {}, Theme>;
    rt: CreateStyledComponentIntrinsic<"rt", {}, Theme>;
    ruby: CreateStyledComponentIntrinsic<"ruby", {}, Theme>;
    s: CreateStyledComponentIntrinsic<"s", {}, Theme>;
    samp: CreateStyledComponentIntrinsic<"samp", {}, Theme>;
    script: CreateStyledComponentIntrinsic<"script", {}, Theme>;
    section: CreateStyledComponentIntrinsic<"section", {}, Theme>;
    select: CreateStyledComponentIntrinsic<"select", {}, Theme>;
    small: CreateStyledComponentIntrinsic<"small", {}, Theme>;
    source: CreateStyledComponentIntrinsic<"source", {}, Theme>;
    span: CreateStyledComponentIntrinsic<"span", {}, Theme>;
    strong: CreateStyledComponentIntrinsic<"strong", {}, Theme>;
    style: CreateStyledComponentIntrinsic<"style", {}, Theme>;
    sub: CreateStyledComponentIntrinsic<"sub", {}, Theme>;
    summary: CreateStyledComponentIntrinsic<"summary", {}, Theme>;
    sup: CreateStyledComponentIntrinsic<"sup", {}, Theme>;
    table: CreateStyledComponentIntrinsic<"table", {}, Theme>;
    tbody: CreateStyledComponentIntrinsic<"tbody", {}, Theme>;
    td: CreateStyledComponentIntrinsic<"td", {}, Theme>;
    textarea: CreateStyledComponentIntrinsic<"textarea", {}, Theme>;
    tfoot: CreateStyledComponentIntrinsic<"tfoot", {}, Theme>;
    th: CreateStyledComponentIntrinsic<"th", {}, Theme>;
    thead: CreateStyledComponentIntrinsic<"thead", {}, Theme>;
    time: CreateStyledComponentIntrinsic<"time", {}, Theme>;
    title: CreateStyledComponentIntrinsic<"title", {}, Theme>;
    tr: CreateStyledComponentIntrinsic<"tr", {}, Theme>;
    track: CreateStyledComponentIntrinsic<"track", {}, Theme>;
    u: CreateStyledComponentIntrinsic<"u", {}, Theme>;
    ul: CreateStyledComponentIntrinsic<"ul", {}, Theme>;
    var: CreateStyledComponentIntrinsic<"var", {}, Theme>;
    video: CreateStyledComponentIntrinsic<"video", {}, Theme>;
    wbr: CreateStyledComponentIntrinsic<"wbr", {}, Theme>;
    /**
     * @desc
     * SVG tags
     */
    circle: CreateStyledComponentIntrinsic<"circle", {}, Theme>;
    clipPath: CreateStyledComponentIntrinsic<"clipPath", {}, Theme>;
    defs: CreateStyledComponentIntrinsic<"defs", {}, Theme>;
    ellipse: CreateStyledComponentIntrinsic<"ellipse", {}, Theme>;
    foreignObject: CreateStyledComponentIntrinsic<"foreignObject", {}, Theme>;
    g: CreateStyledComponentIntrinsic<"g", {}, Theme>;
    image: CreateStyledComponentIntrinsic<"image", {}, Theme>;
    line: CreateStyledComponentIntrinsic<"line", {}, Theme>;
    linearGradient: CreateStyledComponentIntrinsic<"linearGradient", {}, Theme>;
    mask: CreateStyledComponentIntrinsic<"mask", {}, Theme>;
    path: CreateStyledComponentIntrinsic<"path", {}, Theme>;
    pattern: CreateStyledComponentIntrinsic<"pattern", {}, Theme>;
    polygon: CreateStyledComponentIntrinsic<"polygon", {}, Theme>;
    polyline: CreateStyledComponentIntrinsic<"polyline", {}, Theme>;
    radialGradient: CreateStyledComponentIntrinsic<"radialGradient", {}, Theme>;
    rect: CreateStyledComponentIntrinsic<"rect", {}, Theme>;
    stop: CreateStyledComponentIntrinsic<"stop", {}, Theme>;
    svg: CreateStyledComponentIntrinsic<"svg", {}, Theme>;
    text: CreateStyledComponentIntrinsic<"text", {}, Theme>;
    tspan: CreateStyledComponentIntrinsic<"tspan", {}, Theme>;
}
export interface Theme {
    color: Color;
    background: Background;
    typography: Typography;
    animation: Animation;
    easing: Easing;
    input: {
        border: string;
        background: string;
        color: string;
        borderRadius: number;
    };
    layoutMargin: number;
    appBorderColor: string;
    appBorderRadius: number;
    barTextColor: string;
    barSelectedColor: string;
    barBg: string;
    brand: Brand;
    code: {
        [key: string]: string | object;
    };
    [key: string]: any;
}
export interface ThemeVars {
    base: "light" | "dark";
    colorPrimary?: string;
    colorSecondary?: string;
    appBg?: string;
    appContentBg?: string;
    appBorderColor?: string;
    appBorderRadius?: number;
    fontBase?: string;
    fontCode?: string;
    textColor?: string;
    textInverseColor?: string;
    textMutedColor?: string;
    barTextColor?: string;
    barSelectedColor?: string;
    barBg?: string;
    inputBg?: string;
    inputBorder?: string;
    inputTextColor?: string;
    inputBorderRadius?: number;
    brandTitle?: string;
    brandUrl?: string;
    brandImage?: string;
    brandTarget?: string;
    gridCellSize?: number;
}
export type { CSSObject, Keyframes } from "./_modules/@emotion-react-types-index";
export { default as createCache } from "./_modules/@emotion-cache-types-index";
export { default as isPropValid } from "./_modules/@emotion-is-prop-valid-types-index";
export { keyframes, css, jsx, ClassNames, ThemeProvider, CacheProvider } from "./_modules/@emotion-react-types-index";
export { darkenColor as darken, lightenColor as lighten, };
export {};