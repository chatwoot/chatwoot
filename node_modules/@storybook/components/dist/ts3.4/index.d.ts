import { Modifier, Placement } from "./_modules/@popperjs-core-index";
import { Conditional, Parameters } from '@storybook/csf';
import { Theme } from '@storybook/theming';
import { BuiltInParserName } from "./_modules/@types-prettier-index";
import React from 'react';
import { AnchorHTMLAttributes, ButtonHTMLAttributes, Component, ComponentProps, DetailedHTMLProps, ElementType, FC, FunctionComponent, MouseEvent, MutableRefObject, ReactElement, ReactNode, SyntheticEvent } from 'react';
declare class ZoomIFrame extends Component<IZoomIFrameProps> {
    iframe: HTMLIFrameElement;
    componentDidMount(): void;
    shouldComponentUpdate(nextProps: IZoomIFrameProps): boolean;
    setIframeInnerZoom(scale: number): void;
    setIframeZoom(scale: number): void;
    render(): ReactElement<HTMLIFrameElement, string | import("react").JSXElementConstructor<any>> & import("react").ReactNode;
}
declare const ButtonWrapper: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.ButtonHTMLAttributes<HTMLButtonElement>, HTMLButtonElement>, ButtonProps, import("@storybook/theming").Theme>;
declare const DefaultCodeBlock: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement>, HTMLElement>, {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
declare const Item: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.AnchorHTMLAttributes<HTMLAnchorElement>, HTMLAnchorElement>, ItemProps, import("@storybook/theming").Theme>;
declare const LazyColorControl: React.LazyExoticComponent<React.FC<ColorControlProps>>;
declare const LazySyntaxHighlighter: React.LazyExoticComponent<React.FunctionComponent<SyntaxHighlighterProps>>;
declare const LazyWithTooltip: React.LazyExoticComponent<React.FunctionComponent<WithTooltipPureProps & {
    startOpen?: boolean;
}>>;
declare const LazyWithTooltipPure: React.LazyExoticComponent<React.FunctionComponent<WithTooltipPureProps>>;
declare const ProgressWrapper: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>, Pick<React.ClassAttributes<HTMLDivElement> & React.HTMLAttributes<HTMLDivElement>, keyof React.HTMLAttributes<HTMLDivElement>>, import("@storybook/theming").Theme>;
declare const PureLoader: FunctionComponent<LoaderProps & ComponentProps<typeof ProgressWrapper>>;
declare const Svg: import("@storybook/theming").StyledComponent<import("react").SVGProps<SVGSVGElement>, SvgProps, import("@storybook/theming").Theme>;
declare const icons: {
    mobile: string;
    watch: string;
    tablet: string;
    browser: string;
    sidebar: string;
    sidebaralt: string;
    bottombar: string;
    useralt: string;
    user: string;
    useradd: string;
    users: string;
    profile: string;
    bookmark: string;
    bookmarkhollow: string;
    book: string;
    repository: string;
    star: string;
    starhollow: string;
    circle: string;
    circlehollow: string;
    heart: string;
    hearthollow: string;
    facehappy: string;
    facesad: string;
    faceneutral: string;
    lock: string;
    unlock: string;
    key: string;
    arrowleftalt: string;
    arrowrightalt: string;
    sync: string;
    reply: string;
    undo: string;
    transfer: string;
    redirect: string;
    expand: string;
    expandalt: string;
    collapse: string;
    grow: string;
    arrowleft: string;
    arrowup: string;
    arrowdown: string;
    arrowright: string;
    chevrondown: string;
    back: string;
    download: string;
    upload: string;
    proceed: string;
    info: string;
    question: string;
    support: string;
    alert: string;
    bell: string;
    rss: string;
    edit: string;
    paintbrush: string;
    close: string;
    closeAlt: string;
    trash: string;
    cross: string;
    delete: string;
    add: string;
    subtract: string;
    plus: string;
    document: string;
    folder: string;
    component: string;
    calendar: string;
    graphline: string;
    docchart: string;
    doclist: string;
    category: string;
    grid: string;
    copy: string;
    certificate: string;
    print: string;
    listunordered: string;
    graphbar: string;
    menu: string;
    filter: string;
    ellipsis: string;
    cog: string;
    wrench: string;
    nut: string;
    camera: string;
    eye: string;
    eyeclose: string;
    photo: string;
    video: string;
    speaker: string;
    phone: string;
    flag: string;
    pin: string;
    compass: string;
    globe: string;
    location: string;
    search: string;
    zoom: string;
    zoomout: string;
    zoomreset: string;
    timer: string;
    time: string;
    lightning: string;
    lightningoff: string;
    dashboard: string;
    hourglass: string;
    play: string;
    playnext: string;
    playback: string;
    stop: string;
    stopalt: string;
    rewind: string;
    fastforward: string;
    email: string;
    link: string;
    paperclip: string;
    box: string;
    structure: string;
    cpu: string;
    memory: string;
    database: string;
    power: string;
    outbox: string;
    share: string;
    button: string;
    form: string;
    check: string;
    batchaccept: string;
    batchdeny: string;
    home: string;
    admin: string;
    paragraph: string;
    basket: string;
    credit: string;
    shield: string;
    beaker: string;
    thumbsup: string;
    mirror: string;
    switchalt: string;
    commit: string;
    branch: string;
    merge: string;
    pullrequest: string;
    chromatic: string;
    twitter: string;
    google: string;
    gdrive: string;
    youtube: string;
    facebook: string;
    medium: string;
    graphql: string;
    redux: string;
    github: string;
    bitbucket: string;
    gitlab: string;
    azuredevops: string;
    discord: string;
    contrast: string;
    unfold: string;
    sharealt: string;
    accessibility: string;
    accessibilityalt: string;
    markup: string;
    outline: string;
    verified: string;
    comment: string;
    commentadd: string;
    requestchange: string;
    comments: string;
    ruler: string;
};
declare function ZoomElement({ scale, children }: ZoomProps): JSX.Element;
export declare class IFrame extends Component<IFrameProps> {
    iframe: any;
    componentDidMount(): void;
    shouldComponentUpdate(nextProps: IFrameProps): boolean;
    setIframeBodyStyle(style: BodyStyle): any;
    render(): JSX.Element;
}
export declare class TabsState extends Component<TabsStateProps, TabsStateState> {
    static defaultProps: TabsStateProps;
    constructor(props: TabsStateProps);
    handlers: {
        onSelect: (id: string) => void;
    };
    render(): JSX.Element;
}
export declare const A: import("@storybook/theming").StyledComponent<import("react").AnchorHTMLAttributes<HTMLAnchorElement> & {
    children?: import("react").ReactNode;
}, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const ActionBar: FunctionComponent<ActionBarProps>;
export declare const AddonPanel: ({ active, children }: AddonPanelProps) => JSX.Element;
/**
 * Display the props for a component as a props table. Each row is a collection of
 * ArgDefs, usually derived from docgen info for the component.
 */
export declare const ArgsTable: FC<ArgsTableProps>;
export declare const Badge: FunctionComponent<BadgeProps>;
export declare const Bar: import("@storybook/theming").StyledComponent<any, Pick<any, string | number | symbol>, import("@storybook/theming").Theme>;
export declare const Blockquote: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").BlockquoteHTMLAttributes<HTMLElement>, HTMLElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const BooleanControl: FC<BooleanProps>;
export declare const Button: FunctionComponent<ComponentProps<typeof ButtonWrapper>>;
export declare const Code: ({ className, children, ...props }: ComponentProps<typeof DefaultCodeBlock>) => JSX.Element;
export declare const ColorControl: (props: ComponentProps<typeof LazyColorControl>) => JSX.Element;
/**
 * A single color row your styleguide showing title, subtitle and one or more colors, used
 * as a child of `ColorPalette`.
 */
export declare const ColorItem: FunctionComponent<ColorItemProps>;
/**
 * Styleguide documentation for colors, including names, captions, and color swatches,
 * all specified as `ColorItem` children of this wrapper component.
 */
export declare const ColorPalette: FunctionComponent;
export declare const DL: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLDListElement>, HTMLDListElement>, {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const DateControl: FC<DateProps>;
/**
 * A markdown description for a component, typically used to show the
 * components docgen docs.
 */
export declare const Description: FunctionComponent<DescriptionProps>;
export declare const Div: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLDivElement>, HTMLDivElement>, {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const DocsContent: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>, Pick<React.ClassAttributes<HTMLDivElement> & React.HTMLAttributes<HTMLDivElement>, keyof React.HTMLAttributes<HTMLDivElement>>, Theme>;
export declare const DocsPageWrapper: FC;
export declare const DocsWrapper: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>, {}, Theme>;
export declare const DocumentWrapper: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLDivElement>, HTMLDivElement>, {}, import("@storybook/theming").Theme>;
export declare const FilesControl: FunctionComponent<FilesControlProps>;
export declare const FlexBar: FunctionComponent<FlexBarProps>;
export declare const Form: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").FormHTMLAttributes<HTMLFormElement>, HTMLFormElement>, Pick<import("react").ClassAttributes<HTMLFormElement> & import("react").FormHTMLAttributes<HTMLFormElement>, keyof import("react").FormHTMLAttributes<HTMLFormElement>>, import("@storybook/theming").Theme> & {
    Field: import("react").FunctionComponent<FieldProps>;
    Input: import("@storybook/theming").StyledComponent<Pick<Pick<import("react").HTMLProps<HTMLInputElement>, Exclude<keyof import("react").HTMLProps<HTMLInputElement>, keyof InputStyleProps>> & InputStyleProps, "max" | "required" | "type" | "data" | "default" | "high" | "low" | "key" | "id" | "media" | "width" | "start" | "open" | "name" | "color" | "content" | "translate" | "value" | "hidden" | "cite" | "dir" | "form" | "label" | "slot" | "span" | "style" | "summary" | "title" | "pattern" | "acceptCharset" | "action" | "method" | "noValidate" | "target" | "accessKey" | "draggable" | "lang" | "className" | "prefix" | "children" | "contentEditable" | "inputMode" | "nonce" | "tabIndex" | "async" | "disabled" | "multiple" | "manifest" | "wrap" | "accept" | "allowFullScreen" | "allowTransparency" | "alt" | "as" | "autoComplete" | "autoFocus" | "autoPlay" | "capture" | "cellPadding" | "cellSpacing" | "charSet" | "challenge" | "checked" | "classID" | "cols" | "colSpan" | "controls" | "coords" | "crossOrigin" | "dateTime" | "defer" | "download" | "encType" | "formAction" | "formEncType" | "formMethod" | "formNoValidate" | "formTarget" | "frameBorder" | "headers" | "href" | "hrefLang" | "htmlFor" | "httpEquiv" | "integrity" | "keyParams" | "keyType" | "kind" | "list" | "loop" | "marginHeight" | "marginWidth" | "maxLength" | "mediaGroup" | "min" | "minLength" | "muted" | "optimum" | "defaultChecked" | "defaultValue" | "suppressContentEditableWarning" | "suppressHydrationWarning" | "contextMenu" | "placeholder" | "spellCheck" | "radioGroup" | "role" | "about" | "datatype" | "inlist" | "property" | "resource" | "typeof" | "vocab" | "autoCapitalize" | "autoCorrect" | "autoSave" | "itemProp" | "itemScope" | "itemType" | "itemID" | "itemRef" | "results" | "security" | "unselectable" | "is" | "aria-activedescendant" | "aria-atomic" | "aria-autocomplete" | "aria-busy" | "aria-checked" | "aria-colcount" | "aria-colindex" | "aria-colspan" | "aria-controls" | "aria-current" | "aria-describedby" | "aria-details" | "aria-disabled" | "aria-dropeffect" | "aria-errormessage" | "aria-expanded" | "aria-flowto" | "aria-grabbed" | "aria-haspopup" | "aria-hidden" | "aria-invalid" | "aria-keyshortcuts" | "aria-label" | "aria-labelledby" | "aria-level" | "aria-live" | "aria-modal" | "aria-multiline" | "aria-multiselectable" | "aria-orientation" | "aria-owns" | "aria-placeholder" | "aria-posinset" | "aria-pressed" | "aria-readonly" | "aria-relevant" | "aria-required" | "aria-roledescription" | "aria-rowcount" | "aria-rowindex" | "aria-rowspan" | "aria-selected" | "aria-setsize" | "aria-sort" | "aria-valuemax" | "aria-valuemin" | "aria-valuenow" | "aria-valuetext" | "playsInline" | "poster" | "preload" | "readOnly" | "rel" | "reversed" | "rows" | "rowSpan" | "sandbox" | "scope" | "scoped" | "scrolling" | "seamless" | "selected" | "shape" | "sizes" | "src" | "srcDoc" | "srcLang" | "srcSet" | "step" | "useMap" | "wmode" | "dangerouslySetInnerHTML" | "onCopy" | "onCopyCapture" | "onCut" | "onCutCapture" | "onPaste" | "onPasteCapture" | "onCompositionEnd" | "onCompositionEndCapture" | "onCompositionStart" | "onCompositionStartCapture" | "onCompositionUpdate" | "onCompositionUpdateCapture" | "onFocus" | "onFocusCapture" | "onBlur" | "onBlurCapture" | "onChange" | "onChangeCapture" | "onBeforeInput" | "onBeforeInputCapture" | "onInput" | "onInputCapture" | "onReset" | "onResetCapture" | "onSubmit" | "onSubmitCapture" | "onInvalid" | "onInvalidCapture" | "onLoad" | "onLoadCapture" | "onError" | "onErrorCapture" | "onKeyDown" | "onKeyDownCapture" | "onKeyPress" | "onKeyPressCapture" | "onKeyUp" | "onKeyUpCapture" | "onAbort" | "onAbortCapture" | "onCanPlay" | "onCanPlayCapture" | "onCanPlayThrough" | "onCanPlayThroughCapture" | "onDurationChange" | "onDurationChangeCapture" | "onEmptied" | "onEmptiedCapture" | "onEncrypted" | "onEncryptedCapture" | "onEnded" | "onEndedCapture" | "onLoadedData" | "onLoadedDataCapture" | "onLoadedMetadata" | "onLoadedMetadataCapture" | "onLoadStart" | "onLoadStartCapture" | "onPause" | "onPauseCapture" | "onPlay" | "onPlayCapture" | "onPlaying" | "onPlayingCapture" | "onProgress" | "onProgressCapture" | "onRateChange" | "onRateChangeCapture" | "onSeeked" | "onSeekedCapture" | "onSeeking" | "onSeekingCapture" | "onStalled" | "onStalledCapture" | "onSuspend" | "onSuspendCapture" | "onTimeUpdate" | "onTimeUpdateCapture" | "onVolumeChange" | "onVolumeChangeCapture" | "onWaiting" | "onWaitingCapture" | "onAuxClick" | "onAuxClickCapture" | "onClick" | "onClickCapture" | "onContextMenu" | "onContextMenuCapture" | "onDoubleClick" | "onDoubleClickCapture" | "onDrag" | "onDragCapture" | "onDragEnd" | "onDragEndCapture" | "onDragEnter" | "onDragEnterCapture" | "onDragExit" | "onDragExitCapture" | "onDragLeave" | "onDragLeaveCapture" | "onDragOver" | "onDragOverCapture" | "onDragStart" | "onDragStartCapture" | "onDrop" | "onDropCapture" | "onMouseDown" | "onMouseDownCapture" | "onMouseEnter" | "onMouseLeave" | "onMouseMove" | "onMouseMoveCapture" | "onMouseOut" | "onMouseOutCapture" | "onMouseOver" | "onMouseOverCapture" | "onMouseUp" | "onMouseUpCapture" | "onSelect" | "onSelectCapture" | "onTouchCancel" | "onTouchCancelCapture" | "onTouchEnd" | "onTouchEndCapture" | "onTouchMove" | "onTouchMoveCapture" | "onTouchStart" | "onTouchStartCapture" | "onPointerDown" | "onPointerDownCapture" | "onPointerMove" | "onPointerMoveCapture" | "onPointerUp" | "onPointerUpCapture" | "onPointerCancel" | "onPointerCancelCapture" | "onPointerEnter" | "onPointerEnterCapture" | "onPointerLeave" | "onPointerLeaveCapture" | "onPointerOver" | "onPointerOverCapture" | "onPointerOut" | "onPointerOutCapture" | "onGotPointerCapture" | "onGotPointerCaptureCapture" | "onLostPointerCapture" | "onLostPointerCaptureCapture" | "onScroll" | "onScrollCapture" | "onWheel" | "onWheelCapture" | "onAnimationStart" | "onAnimationStartCapture" | "onAnimationEnd" | "onAnimationEndCapture" | "onAnimationIteration" | "onAnimationIterationCapture" | "onTransitionEnd" | "onTransitionEndCapture" | keyof InputStyleProps> & import("react").RefAttributes<any>, InputStyleProps, import("@storybook/theming").Theme> & {
        displayName: string;
    };
    Select: import("@storybook/theming").StyledComponent<Pick<import("react").SelectHTMLAttributes<HTMLSelectElement>, Exclude<keyof import("react").SelectHTMLAttributes<HTMLSelectElement>, keyof InputStyleProps>> & InputStyleProps & import("react").RefAttributes<any>, Pick<import("react").SelectHTMLAttributes<HTMLSelectElement>, Exclude<keyof import("react").SelectHTMLAttributes<HTMLSelectElement>, keyof InputStyleProps>> & InputStyleProps, import("@storybook/theming").Theme> & {
        displayName: string;
    };
    Textarea: import("@storybook/theming").StyledComponent<Pick<import("react-textarea-autosize").TextareaAutosizeProps, Exclude<keyof import("react-textarea-autosize").TextareaAutosizeProps, keyof InputStyleProps>> & InputStyleProps & import("react").RefAttributes<any>, Pick<import("react-textarea-autosize").TextareaAutosizeProps, Exclude<keyof import("react-textarea-autosize").TextareaAutosizeProps, keyof InputStyleProps>> & InputStyleProps, import("@storybook/theming").Theme> & {
        displayName: string;
    };
    Button: import("react").FunctionComponent<any>;
};
export declare const H1: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const H2: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const H3: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const H4: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const H5: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const H6: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const HR: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHRElement>, HTMLHRElement>, Pick<import("react").ClassAttributes<HTMLHRElement> & import("react").HTMLAttributes<HTMLHRElement>, keyof import("react").HTMLAttributes<HTMLHRElement>>, import("@storybook/theming").Theme>;
export declare const IconButton: import("@storybook/theming").StyledComponent<(Pick<BarButtonProps, "type" | "key" | "id" | "name" | "color" | "translate" | "value" | "hidden" | "dir" | "form" | "slot" | "style" | "title" | "accessKey" | "draggable" | "lang" | "className" | "prefix" | "children" | "contentEditable" | "inputMode" | "tabIndex" | "disabled" | "autoFocus" | "formAction" | "formEncType" | "formMethod" | "formNoValidate" | "formTarget" | "href" | "defaultChecked" | "defaultValue" | "suppressContentEditableWarning" | "suppressHydrationWarning" | "contextMenu" | "placeholder" | "spellCheck" | "radioGroup" | "role" | "about" | "datatype" | "inlist" | "property" | "resource" | "typeof" | "vocab" | "autoCapitalize" | "autoCorrect" | "autoSave" | "itemProp" | "itemScope" | "itemType" | "itemID" | "itemRef" | "results" | "security" | "unselectable" | "is" | "aria-activedescendant" | "aria-atomic" | "aria-autocomplete" | "aria-busy" | "aria-checked" | "aria-colcount" | "aria-colindex" | "aria-colspan" | "aria-controls" | "aria-current" | "aria-describedby" | "aria-details" | "aria-disabled" | "aria-dropeffect" | "aria-errormessage" | "aria-expanded" | "aria-flowto" | "aria-grabbed" | "aria-haspopup" | "aria-hidden" | "aria-invalid" | "aria-keyshortcuts" | "aria-label" | "aria-labelledby" | "aria-level" | "aria-live" | "aria-modal" | "aria-multiline" | "aria-multiselectable" | "aria-orientation" | "aria-owns" | "aria-placeholder" | "aria-posinset" | "aria-pressed" | "aria-readonly" | "aria-relevant" | "aria-required" | "aria-roledescription" | "aria-rowcount" | "aria-rowindex" | "aria-rowspan" | "aria-selected" | "aria-setsize" | "aria-sort" | "aria-valuemax" | "aria-valuemin" | "aria-valuenow" | "aria-valuetext" | "dangerouslySetInnerHTML" | "onCopy" | "onCopyCapture" | "onCut" | "onCutCapture" | "onPaste" | "onPasteCapture" | "onCompositionEnd" | "onCompositionEndCapture" | "onCompositionStart" | "onCompositionStartCapture" | "onCompositionUpdate" | "onCompositionUpdateCapture" | "onFocus" | "onFocusCapture" | "onBlur" | "onBlurCapture" | "onChange" | "onChangeCapture" | "onBeforeInput" | "onBeforeInputCapture" | "onInput" | "onInputCapture" | "onReset" | "onResetCapture" | "onSubmit" | "onSubmitCapture" | "onInvalid" | "onInvalidCapture" | "onLoad" | "onLoadCapture" | "onError" | "onErrorCapture" | "onKeyDown" | "onKeyDownCapture" | "onKeyPress" | "onKeyPressCapture" | "onKeyUp" | "onKeyUpCapture" | "onAbort" | "onAbortCapture" | "onCanPlay" | "onCanPlayCapture" | "onCanPlayThrough" | "onCanPlayThroughCapture" | "onDurationChange" | "onDurationChangeCapture" | "onEmptied" | "onEmptiedCapture" | "onEncrypted" | "onEncryptedCapture" | "onEnded" | "onEndedCapture" | "onLoadedData" | "onLoadedDataCapture" | "onLoadedMetadata" | "onLoadedMetadataCapture" | "onLoadStart" | "onLoadStartCapture" | "onPause" | "onPauseCapture" | "onPlay" | "onPlayCapture" | "onPlaying" | "onPlayingCapture" | "onProgress" | "onProgressCapture" | "onRateChange" | "onRateChangeCapture" | "onSeeked" | "onSeekedCapture" | "onSeeking" | "onSeekingCapture" | "onStalled" | "onStalledCapture" | "onSuspend" | "onSuspendCapture" | "onTimeUpdate" | "onTimeUpdateCapture" | "onVolumeChange" | "onVolumeChangeCapture" | "onWaiting" | "onWaitingCapture" | "onAuxClick" | "onAuxClickCapture" | "onClick" | "onClickCapture" | "onContextMenu" | "onContextMenuCapture" | "onDoubleClick" | "onDoubleClickCapture" | "onDrag" | "onDragCapture" | "onDragEnd" | "onDragEndCapture" | "onDragEnter" | "onDragEnterCapture" | "onDragExit" | "onDragExitCapture" | "onDragLeave" | "onDragLeaveCapture" | "onDragOver" | "onDragOverCapture" | "onDragStart" | "onDragStartCapture" | "onDrop" | "onDropCapture" | "onMouseDown" | "onMouseDownCapture" | "onMouseEnter" | "onMouseLeave" | "onMouseMove" | "onMouseMoveCapture" | "onMouseOut" | "onMouseOutCapture" | "onMouseOver" | "onMouseOverCapture" | "onMouseUp" | "onMouseUpCapture" | "onSelect" | "onSelectCapture" | "onTouchCancel" | "onTouchCancelCapture" | "onTouchEnd" | "onTouchEndCapture" | "onTouchMove" | "onTouchMoveCapture" | "onTouchStart" | "onTouchStartCapture" | "onPointerDown" | "onPointerDownCapture" | "onPointerMove" | "onPointerMoveCapture" | "onPointerUp" | "onPointerUpCapture" | "onPointerCancel" | "onPointerCancelCapture" | "onPointerEnter" | "onPointerEnterCapture" | "onPointerLeave" | "onPointerLeaveCapture" | "onPointerOver" | "onPointerOverCapture" | "onPointerOut" | "onPointerOutCapture" | "onGotPointerCapture" | "onGotPointerCaptureCapture" | "onLostPointerCapture" | "onLostPointerCaptureCapture" | "onScroll" | "onScrollCapture" | "onWheel" | "onWheelCapture" | "onAnimationStart" | "onAnimationStartCapture" | "onAnimationEnd" | "onAnimationEndCapture" | "onAnimationIteration" | "onAnimationIterationCapture" | "onTransitionEnd" | "onTransitionEndCapture"> & {
    ref?: React.Ref<HTMLButtonElement>;
}) | (Pick<BarLinkProps, "type" | "key" | "id" | "media" | "color" | "translate" | "hidden" | "dir" | "slot" | "style" | "title" | "target" | "accessKey" | "draggable" | "lang" | "className" | "prefix" | "children" | "contentEditable" | "inputMode" | "tabIndex" | "download" | "href" | "hrefLang" | "defaultChecked" | "defaultValue" | "suppressContentEditableWarning" | "suppressHydrationWarning" | "contextMenu" | "placeholder" | "spellCheck" | "radioGroup" | "role" | "about" | "datatype" | "inlist" | "property" | "resource" | "typeof" | "vocab" | "autoCapitalize" | "autoCorrect" | "autoSave" | "itemProp" | "itemScope" | "itemType" | "itemID" | "itemRef" | "results" | "security" | "unselectable" | "is" | "aria-activedescendant" | "aria-atomic" | "aria-autocomplete" | "aria-busy" | "aria-checked" | "aria-colcount" | "aria-colindex" | "aria-colspan" | "aria-controls" | "aria-current" | "aria-describedby" | "aria-details" | "aria-disabled" | "aria-dropeffect" | "aria-errormessage" | "aria-expanded" | "aria-flowto" | "aria-grabbed" | "aria-haspopup" | "aria-hidden" | "aria-invalid" | "aria-keyshortcuts" | "aria-label" | "aria-labelledby" | "aria-level" | "aria-live" | "aria-modal" | "aria-multiline" | "aria-multiselectable" | "aria-orientation" | "aria-owns" | "aria-placeholder" | "aria-posinset" | "aria-pressed" | "aria-readonly" | "aria-relevant" | "aria-required" | "aria-roledescription" | "aria-rowcount" | "aria-rowindex" | "aria-rowspan" | "aria-selected" | "aria-setsize" | "aria-sort" | "aria-valuemax" | "aria-valuemin" | "aria-valuenow" | "aria-valuetext" | "rel" | "dangerouslySetInnerHTML" | "onCopy" | "onCopyCapture" | "onCut" | "onCutCapture" | "onPaste" | "onPasteCapture" | "onCompositionEnd" | "onCompositionEndCapture" | "onCompositionStart" | "onCompositionStartCapture" | "onCompositionUpdate" | "onCompositionUpdateCapture" | "onFocus" | "onFocusCapture" | "onBlur" | "onBlurCapture" | "onChange" | "onChangeCapture" | "onBeforeInput" | "onBeforeInputCapture" | "onInput" | "onInputCapture" | "onReset" | "onResetCapture" | "onSubmit" | "onSubmitCapture" | "onInvalid" | "onInvalidCapture" | "onLoad" | "onLoadCapture" | "onError" | "onErrorCapture" | "onKeyDown" | "onKeyDownCapture" | "onKeyPress" | "onKeyPressCapture" | "onKeyUp" | "onKeyUpCapture" | "onAbort" | "onAbortCapture" | "onCanPlay" | "onCanPlayCapture" | "onCanPlayThrough" | "onCanPlayThroughCapture" | "onDurationChange" | "onDurationChangeCapture" | "onEmptied" | "onEmptiedCapture" | "onEncrypted" | "onEncryptedCapture" | "onEnded" | "onEndedCapture" | "onLoadedData" | "onLoadedDataCapture" | "onLoadedMetadata" | "onLoadedMetadataCapture" | "onLoadStart" | "onLoadStartCapture" | "onPause" | "onPauseCapture" | "onPlay" | "onPlayCapture" | "onPlaying" | "onPlayingCapture" | "onProgress" | "onProgressCapture" | "onRateChange" | "onRateChangeCapture" | "onSeeked" | "onSeekedCapture" | "onSeeking" | "onSeekingCapture" | "onStalled" | "onStalledCapture" | "onSuspend" | "onSuspendCapture" | "onTimeUpdate" | "onTimeUpdateCapture" | "onVolumeChange" | "onVolumeChangeCapture" | "onWaiting" | "onWaitingCapture" | "onAuxClick" | "onAuxClickCapture" | "onClick" | "onClickCapture" | "onContextMenu" | "onContextMenuCapture" | "onDoubleClick" | "onDoubleClickCapture" | "onDrag" | "onDragCapture" | "onDragEnd" | "onDragEndCapture" | "onDragEnter" | "onDragEnterCapture" | "onDragExit" | "onDragExitCapture" | "onDragLeave" | "onDragLeaveCapture" | "onDragOver" | "onDragOverCapture" | "onDragStart" | "onDragStartCapture" | "onDrop" | "onDropCapture" | "onMouseDown" | "onMouseDownCapture" | "onMouseEnter" | "onMouseLeave" | "onMouseMove" | "onMouseMoveCapture" | "onMouseOut" | "onMouseOutCapture" | "onMouseOver" | "onMouseOverCapture" | "onMouseUp" | "onMouseUpCapture" | "onSelect" | "onSelectCapture" | "onTouchCancel" | "onTouchCancelCapture" | "onTouchEnd" | "onTouchEndCapture" | "onTouchMove" | "onTouchMoveCapture" | "onTouchStart" | "onTouchStartCapture" | "onPointerDown" | "onPointerDownCapture" | "onPointerMove" | "onPointerMoveCapture" | "onPointerUp" | "onPointerUpCapture" | "onPointerCancel" | "onPointerCancelCapture" | "onPointerEnter" | "onPointerEnterCapture" | "onPointerLeave" | "onPointerLeaveCapture" | "onPointerOver" | "onPointerOverCapture" | "onPointerOut" | "onPointerOutCapture" | "onGotPointerCapture" | "onGotPointerCaptureCapture" | "onLostPointerCapture" | "onLostPointerCaptureCapture" | "onScroll" | "onScrollCapture" | "onWheel" | "onWheelCapture" | "onAnimationStart" | "onAnimationStartCapture" | "onAnimationEnd" | "onAnimationEndCapture" | "onAnimationIteration" | "onAnimationIterationCapture" | "onTransitionEnd" | "onTransitionEndCapture" | "ping" | "referrerPolicy"> & {
    ref?: React.Ref<HTMLAnchorElement>;
}), IconButtonProps, import("@storybook/theming").Theme>;
/**
 * Show a grid of icons, as specified by `IconItem`.
 */
export declare const IconGallery: FunctionComponent;
/**
 * An individual icon with a caption and an example (passed as `children`).
 */
export declare const IconItem: FunctionComponent<IconItemProps>;
export declare const Icons: React.NamedExoticComponent<IconsProps>;
export declare const Img: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").ImgHTMLAttributes<HTMLImageElement>, HTMLImageElement>, Pick<import("react").ClassAttributes<HTMLImageElement> & import("react").ImgHTMLAttributes<HTMLImageElement>, keyof import("react").ImgHTMLAttributes<HTMLImageElement>>, import("@storybook/theming").Theme>;
export declare const LI: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").LiHTMLAttributes<HTMLLIElement>, HTMLLIElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const Link: FunctionComponent<LinkProps & AProps>;
export declare const Loader: FunctionComponent<ComponentProps<typeof PureLoader>>;
export declare const NoControlsWarning: () => JSX.Element;
export declare const NumberControl: FC<NumberProps>;
export declare const OL: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").OlHTMLAttributes<HTMLOListElement>, HTMLOListElement>, {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const ObjectControl: FC<ObjectProps>;
export declare const OptionsControl: FC<OptionsProps>;
export declare const P: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLParagraphElement>, HTMLParagraphElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const Placeholder: FunctionComponent;
export declare const Pre: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLPreElement>, HTMLPreElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
/**
 * A preview component for showing one or more component `Story`
 * items. The preview also shows the source for the component
 * as a drop-down.
 */
export declare const Preview: FunctionComponent<PreviewProps>;
export declare const PreviewSkeleton: () => JSX.Element;
export declare const RangeControl: FC<RangeProps>;
export declare const ScrollArea: FunctionComponent<ScrollAreaProps>;
export declare const Separator: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLSpanElement>, HTMLSpanElement>, SeparatorProps, import("@storybook/theming").Theme>;
/**
 * Syntax-highlighted source code for a component (or anything!)
 */
export declare const Source: FunctionComponent<SourceProps>;
export declare const Spaced: FunctionComponent<SpacedProps>;
export declare const Span: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLSpanElement>, HTMLSpanElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
/**
 * A story element, either rendered inline or in an iframe,
 * with configurable height.
 */
export declare const Story: FunctionComponent<StoryProps & {
    inline?: boolean;
    error?: StoryError;
}>;
export declare const StorySkeleton: () => JSX.Element;
export declare const StorybookIcon: FunctionComponent<{}>;
export declare const StorybookLogo: FunctionComponent<StorybookLogoProps>;
export declare const StyledSyntaxHighlighter: import("@storybook/theming").StyledComponent<SyntaxHighlighterBaseProps & SyntaxHighlighterCustomProps & {
    children?: React.ReactNode;
}, {}, import("@storybook/theming").Theme>;
export declare const Subtitle: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {}, Theme>;
export declare const Symbols: React.NamedExoticComponent<SymbolsProps>;
export declare const SyntaxHighlighter: (props: ComponentProps<typeof LazySyntaxHighlighter>) => JSX.Element;
export declare const TT: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLTitleElement>, HTMLTitleElement>, {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const TabBar: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement>, Pick<React.ClassAttributes<HTMLDivElement> & React.HTMLAttributes<HTMLDivElement>, keyof React.HTMLAttributes<HTMLDivElement>>, import("@storybook/theming").Theme>;
export declare const TabButton: import("@storybook/theming").StyledComponent<(Pick<BarButtonProps, "type" | "key" | "id" | "name" | "color" | "translate" | "value" | "hidden" | "dir" | "form" | "slot" | "style" | "title" | "accessKey" | "draggable" | "lang" | "className" | "prefix" | "children" | "contentEditable" | "inputMode" | "tabIndex" | "disabled" | "autoFocus" | "formAction" | "formEncType" | "formMethod" | "formNoValidate" | "formTarget" | "href" | "defaultChecked" | "defaultValue" | "suppressContentEditableWarning" | "suppressHydrationWarning" | "contextMenu" | "placeholder" | "spellCheck" | "radioGroup" | "role" | "about" | "datatype" | "inlist" | "property" | "resource" | "typeof" | "vocab" | "autoCapitalize" | "autoCorrect" | "autoSave" | "itemProp" | "itemScope" | "itemType" | "itemID" | "itemRef" | "results" | "security" | "unselectable" | "is" | "aria-activedescendant" | "aria-atomic" | "aria-autocomplete" | "aria-busy" | "aria-checked" | "aria-colcount" | "aria-colindex" | "aria-colspan" | "aria-controls" | "aria-current" | "aria-describedby" | "aria-details" | "aria-disabled" | "aria-dropeffect" | "aria-errormessage" | "aria-expanded" | "aria-flowto" | "aria-grabbed" | "aria-haspopup" | "aria-hidden" | "aria-invalid" | "aria-keyshortcuts" | "aria-label" | "aria-labelledby" | "aria-level" | "aria-live" | "aria-modal" | "aria-multiline" | "aria-multiselectable" | "aria-orientation" | "aria-owns" | "aria-placeholder" | "aria-posinset" | "aria-pressed" | "aria-readonly" | "aria-relevant" | "aria-required" | "aria-roledescription" | "aria-rowcount" | "aria-rowindex" | "aria-rowspan" | "aria-selected" | "aria-setsize" | "aria-sort" | "aria-valuemax" | "aria-valuemin" | "aria-valuenow" | "aria-valuetext" | "dangerouslySetInnerHTML" | "onCopy" | "onCopyCapture" | "onCut" | "onCutCapture" | "onPaste" | "onPasteCapture" | "onCompositionEnd" | "onCompositionEndCapture" | "onCompositionStart" | "onCompositionStartCapture" | "onCompositionUpdate" | "onCompositionUpdateCapture" | "onFocus" | "onFocusCapture" | "onBlur" | "onBlurCapture" | "onChange" | "onChangeCapture" | "onBeforeInput" | "onBeforeInputCapture" | "onInput" | "onInputCapture" | "onReset" | "onResetCapture" | "onSubmit" | "onSubmitCapture" | "onInvalid" | "onInvalidCapture" | "onLoad" | "onLoadCapture" | "onError" | "onErrorCapture" | "onKeyDown" | "onKeyDownCapture" | "onKeyPress" | "onKeyPressCapture" | "onKeyUp" | "onKeyUpCapture" | "onAbort" | "onAbortCapture" | "onCanPlay" | "onCanPlayCapture" | "onCanPlayThrough" | "onCanPlayThroughCapture" | "onDurationChange" | "onDurationChangeCapture" | "onEmptied" | "onEmptiedCapture" | "onEncrypted" | "onEncryptedCapture" | "onEnded" | "onEndedCapture" | "onLoadedData" | "onLoadedDataCapture" | "onLoadedMetadata" | "onLoadedMetadataCapture" | "onLoadStart" | "onLoadStartCapture" | "onPause" | "onPauseCapture" | "onPlay" | "onPlayCapture" | "onPlaying" | "onPlayingCapture" | "onProgress" | "onProgressCapture" | "onRateChange" | "onRateChangeCapture" | "onSeeked" | "onSeekedCapture" | "onSeeking" | "onSeekingCapture" | "onStalled" | "onStalledCapture" | "onSuspend" | "onSuspendCapture" | "onTimeUpdate" | "onTimeUpdateCapture" | "onVolumeChange" | "onVolumeChangeCapture" | "onWaiting" | "onWaitingCapture" | "onAuxClick" | "onAuxClickCapture" | "onClick" | "onClickCapture" | "onContextMenu" | "onContextMenuCapture" | "onDoubleClick" | "onDoubleClickCapture" | "onDrag" | "onDragCapture" | "onDragEnd" | "onDragEndCapture" | "onDragEnter" | "onDragEnterCapture" | "onDragExit" | "onDragExitCapture" | "onDragLeave" | "onDragLeaveCapture" | "onDragOver" | "onDragOverCapture" | "onDragStart" | "onDragStartCapture" | "onDrop" | "onDropCapture" | "onMouseDown" | "onMouseDownCapture" | "onMouseEnter" | "onMouseLeave" | "onMouseMove" | "onMouseMoveCapture" | "onMouseOut" | "onMouseOutCapture" | "onMouseOver" | "onMouseOverCapture" | "onMouseUp" | "onMouseUpCapture" | "onSelect" | "onSelectCapture" | "onTouchCancel" | "onTouchCancelCapture" | "onTouchEnd" | "onTouchEndCapture" | "onTouchMove" | "onTouchMoveCapture" | "onTouchStart" | "onTouchStartCapture" | "onPointerDown" | "onPointerDownCapture" | "onPointerMove" | "onPointerMoveCapture" | "onPointerUp" | "onPointerUpCapture" | "onPointerCancel" | "onPointerCancelCapture" | "onPointerEnter" | "onPointerEnterCapture" | "onPointerLeave" | "onPointerLeaveCapture" | "onPointerOver" | "onPointerOverCapture" | "onPointerOut" | "onPointerOutCapture" | "onGotPointerCapture" | "onGotPointerCaptureCapture" | "onLostPointerCapture" | "onLostPointerCaptureCapture" | "onScroll" | "onScrollCapture" | "onWheel" | "onWheelCapture" | "onAnimationStart" | "onAnimationStartCapture" | "onAnimationEnd" | "onAnimationEndCapture" | "onAnimationIteration" | "onAnimationIterationCapture" | "onTransitionEnd" | "onTransitionEndCapture"> & {
    ref?: React.Ref<HTMLButtonElement>;
}) | (Pick<BarLinkProps, "type" | "key" | "id" | "media" | "color" | "translate" | "hidden" | "dir" | "slot" | "style" | "title" | "target" | "accessKey" | "draggable" | "lang" | "className" | "prefix" | "children" | "contentEditable" | "inputMode" | "tabIndex" | "download" | "href" | "hrefLang" | "defaultChecked" | "defaultValue" | "suppressContentEditableWarning" | "suppressHydrationWarning" | "contextMenu" | "placeholder" | "spellCheck" | "radioGroup" | "role" | "about" | "datatype" | "inlist" | "property" | "resource" | "typeof" | "vocab" | "autoCapitalize" | "autoCorrect" | "autoSave" | "itemProp" | "itemScope" | "itemType" | "itemID" | "itemRef" | "results" | "security" | "unselectable" | "is" | "aria-activedescendant" | "aria-atomic" | "aria-autocomplete" | "aria-busy" | "aria-checked" | "aria-colcount" | "aria-colindex" | "aria-colspan" | "aria-controls" | "aria-current" | "aria-describedby" | "aria-details" | "aria-disabled" | "aria-dropeffect" | "aria-errormessage" | "aria-expanded" | "aria-flowto" | "aria-grabbed" | "aria-haspopup" | "aria-hidden" | "aria-invalid" | "aria-keyshortcuts" | "aria-label" | "aria-labelledby" | "aria-level" | "aria-live" | "aria-modal" | "aria-multiline" | "aria-multiselectable" | "aria-orientation" | "aria-owns" | "aria-placeholder" | "aria-posinset" | "aria-pressed" | "aria-readonly" | "aria-relevant" | "aria-required" | "aria-roledescription" | "aria-rowcount" | "aria-rowindex" | "aria-rowspan" | "aria-selected" | "aria-setsize" | "aria-sort" | "aria-valuemax" | "aria-valuemin" | "aria-valuenow" | "aria-valuetext" | "rel" | "dangerouslySetInnerHTML" | "onCopy" | "onCopyCapture" | "onCut" | "onCutCapture" | "onPaste" | "onPasteCapture" | "onCompositionEnd" | "onCompositionEndCapture" | "onCompositionStart" | "onCompositionStartCapture" | "onCompositionUpdate" | "onCompositionUpdateCapture" | "onFocus" | "onFocusCapture" | "onBlur" | "onBlurCapture" | "onChange" | "onChangeCapture" | "onBeforeInput" | "onBeforeInputCapture" | "onInput" | "onInputCapture" | "onReset" | "onResetCapture" | "onSubmit" | "onSubmitCapture" | "onInvalid" | "onInvalidCapture" | "onLoad" | "onLoadCapture" | "onError" | "onErrorCapture" | "onKeyDown" | "onKeyDownCapture" | "onKeyPress" | "onKeyPressCapture" | "onKeyUp" | "onKeyUpCapture" | "onAbort" | "onAbortCapture" | "onCanPlay" | "onCanPlayCapture" | "onCanPlayThrough" | "onCanPlayThroughCapture" | "onDurationChange" | "onDurationChangeCapture" | "onEmptied" | "onEmptiedCapture" | "onEncrypted" | "onEncryptedCapture" | "onEnded" | "onEndedCapture" | "onLoadedData" | "onLoadedDataCapture" | "onLoadedMetadata" | "onLoadedMetadataCapture" | "onLoadStart" | "onLoadStartCapture" | "onPause" | "onPauseCapture" | "onPlay" | "onPlayCapture" | "onPlaying" | "onPlayingCapture" | "onProgress" | "onProgressCapture" | "onRateChange" | "onRateChangeCapture" | "onSeeked" | "onSeekedCapture" | "onSeeking" | "onSeekingCapture" | "onStalled" | "onStalledCapture" | "onSuspend" | "onSuspendCapture" | "onTimeUpdate" | "onTimeUpdateCapture" | "onVolumeChange" | "onVolumeChangeCapture" | "onWaiting" | "onWaitingCapture" | "onAuxClick" | "onAuxClickCapture" | "onClick" | "onClickCapture" | "onContextMenu" | "onContextMenuCapture" | "onDoubleClick" | "onDoubleClickCapture" | "onDrag" | "onDragCapture" | "onDragEnd" | "onDragEndCapture" | "onDragEnter" | "onDragEnterCapture" | "onDragExit" | "onDragExitCapture" | "onDragLeave" | "onDragLeaveCapture" | "onDragOver" | "onDragOverCapture" | "onDragStart" | "onDragStartCapture" | "onDrop" | "onDropCapture" | "onMouseDown" | "onMouseDownCapture" | "onMouseEnter" | "onMouseLeave" | "onMouseMove" | "onMouseMoveCapture" | "onMouseOut" | "onMouseOutCapture" | "onMouseOver" | "onMouseOverCapture" | "onMouseUp" | "onMouseUpCapture" | "onSelect" | "onSelectCapture" | "onTouchCancel" | "onTouchCancelCapture" | "onTouchEnd" | "onTouchEndCapture" | "onTouchMove" | "onTouchMoveCapture" | "onTouchStart" | "onTouchStartCapture" | "onPointerDown" | "onPointerDownCapture" | "onPointerMove" | "onPointerMoveCapture" | "onPointerUp" | "onPointerUpCapture" | "onPointerCancel" | "onPointerCancelCapture" | "onPointerEnter" | "onPointerEnterCapture" | "onPointerLeave" | "onPointerLeaveCapture" | "onPointerOver" | "onPointerOverCapture" | "onPointerOut" | "onPointerOutCapture" | "onGotPointerCapture" | "onGotPointerCaptureCapture" | "onLostPointerCapture" | "onLostPointerCaptureCapture" | "onScroll" | "onScrollCapture" | "onWheel" | "onWheelCapture" | "onAnimationStart" | "onAnimationStartCapture" | "onAnimationEnd" | "onAnimationEndCapture" | "onAnimationIteration" | "onAnimationIterationCapture" | "onTransitionEnd" | "onTransitionEndCapture" | "ping" | "referrerPolicy"> & {
    ref?: React.Ref<HTMLAnchorElement>;
}), TabButtonProps, import("@storybook/theming").Theme>;
export declare const TabWrapper: FunctionComponent<TabWrapperProps>;
export declare const TabbedArgsTable: FC<TabbedArgsTableProps>;
export declare const Table: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").TableHTMLAttributes<HTMLTableElement>, HTMLTableElement>, {
    theme: import("@storybook/theming").Theme;
} & {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const TableWrapper: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.TableHTMLAttributes<HTMLTableElement>, HTMLTableElement>, {
    compact?: boolean;
    inAddonPanel?: boolean;
    isLoading?: boolean;
}, import("@storybook/theming").Theme>;
export declare const Tabs: FunctionComponent<TabsProps>;
export declare const TextControl: FC<TextProps>;
export declare const Title: import("@storybook/theming").StyledComponent<React.DetailedHTMLProps<React.HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>, {}, Theme>;
export declare const TooltipLinkList: FunctionComponent<TooltipLinkListProps>;
export declare const TooltipMessage: FunctionComponent<TooltipMessageProps>;
export declare const TooltipNote: FunctionComponent<TooltipNoteProps>;
/**
 * Convenient styleguide documentation showing examples of type
 * with different sizes and weights and configurable sample text.
 */
export declare const Typeset: FunctionComponent<TypesetProps>;
export declare const UL: import("@storybook/theming").StyledComponent<import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLUListElement>, HTMLUListElement>, {
    theme: import("@storybook/theming").Theme;
}, import("@storybook/theming").Theme>;
export declare const WithTooltip: (props: ComponentProps<typeof LazyWithTooltip>) => JSX.Element;
export declare const WithTooltipPure: (props: ComponentProps<typeof LazyWithTooltipPure>) => JSX.Element;
export declare const Zoom: {
    Element: typeof ZoomElement;
    IFrame: typeof ZoomIFrame;
};
export declare const argsTableLoadingData: ArgsTableDataProps;
export declare const components: {
    h1: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>) => JSX.Element;
    h2: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>) => JSX.Element;
    h3: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>) => JSX.Element;
    h4: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>) => JSX.Element;
    h5: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>) => JSX.Element;
    h6: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHeadingElement>, HTMLHeadingElement>) => JSX.Element;
    pre: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLPreElement>, HTMLPreElement>) => JSX.Element;
    a: (props: import("react").DetailedHTMLProps<import("react").AnchorHTMLAttributes<HTMLAnchorElement>, HTMLAnchorElement>) => JSX.Element;
    hr: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLHRElement>, HTMLHRElement>) => JSX.Element;
    dl: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLDListElement>, HTMLDListElement>) => JSX.Element;
    blockquote: (props: import("react").DetailedHTMLProps<import("react").BlockquoteHTMLAttributes<HTMLElement>, HTMLElement>) => JSX.Element;
    table: (props: import("react").DetailedHTMLProps<import("react").TableHTMLAttributes<HTMLTableElement>, HTMLTableElement>) => JSX.Element;
    img: (props: import("react").DetailedHTMLProps<import("react").ImgHTMLAttributes<HTMLImageElement>, HTMLImageElement>) => JSX.Element;
    div: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLDivElement>, HTMLDivElement>) => JSX.Element;
    span: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLSpanElement>, HTMLSpanElement>) => JSX.Element;
    li: (props: import("react").DetailedHTMLProps<import("react").LiHTMLAttributes<HTMLLIElement>, HTMLLIElement>) => JSX.Element;
    ul: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLUListElement>, HTMLUListElement>) => JSX.Element;
    ol: (props: import("react").DetailedHTMLProps<import("react").OlHTMLAttributes<HTMLOListElement>, HTMLOListElement>) => JSX.Element;
    p: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLParagraphElement>, HTMLParagraphElement>) => JSX.Element;
    code: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLElement>, HTMLElement>) => JSX.Element;
    tt: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLTitleElement>, HTMLTitleElement>) => JSX.Element;
    resetwrapper: (props: import("react").DetailedHTMLProps<import("react").HTMLAttributes<HTMLDivElement>, HTMLDivElement>) => JSX.Element;
};
export declare const format: (value: NumberValue) => string;
export declare const formatDate: (value: Date | number) => string;
export declare const formatTime: (value: Date | number) => string;
export declare const getStoryHref: (baseUrl: string, storyId: string, additionalParams?: Record<string, string>) => string;
export declare const interleaveSeparators: (list: any[]) => any;
export declare const nameSpaceClassNames: ({ ...props }: {
    [x: string]: any;
}, key: string) => {
    [x: string]: any;
};
export declare const parse: (value: string) => number;
export declare const parseDate: (value: string) => Date;
export declare const parseTime: (value: string) => Date;
export declare const resetComponents: Record<string, ElementType>;
export declare enum ArgsTableError {
    NO_COMPONENT = "No component found.",
    ARGS_UNSUPPORTED = "Args unsupported. See Args documentation for your framework."
}
export declare enum SourceError {
    NO_STORY = "There\u2019s no story here.",
    SOURCE_UNAVAILABLE = "Oh no! The source is not available."
}
export declare enum StoryError {
    NO_STORY = "No component or story to display"
}
export declare type AProps = AnchorHTMLAttributes<HTMLAnchorElement>;
export declare type Alignments = "end" | "center" | "start";
export declare type ArgsTableProps = ArgsTableOptionProps & (ArgsTableDataProps | ArgsTableErrorProps | ArgsTableLoadingProps);
export declare type BooleanProps = ControlProps<BooleanValue> & BooleanConfig;
export declare type BooleanValue = boolean;
export declare type ColorControlProps = ControlProps<ColorValue> & ColorConfig;
export declare type ColorProps = ColorControlProps;
export declare type ColorValue = string;
export declare type Colors = string[] | {
    [key: string]: string;
};
export declare type Control = BooleanConfig | ColorConfig | DateConfig | NumberConfig | ObjectConfig | OptionsConfig | RangeConfig | TextConfig;
export declare type ControlType = "array" | "boolean" | "color" | "date" | "number" | "range" | "object" | OptionsControlType | "text";
export declare type Controls = Record<string, Control>;
export declare type DateProps = ControlProps<DateValue> & DateConfig;
export declare type DateValue = Date | number;
export declare type FuncChildren = () => void;
export declare type Globals = {
    [name: string]: any;
};
export declare type IFrameStoryProps = CommonProps;
export declare type IZoomIFrameProps = {
    scale: number;
    children: ReactElement<HTMLIFrameElement>;
    iFrameRef: MutableRefObject<HTMLIFrameElement>;
    active?: boolean;
};
export declare type IconKey = keyof typeof icons;
export declare type LinkWrapperType = FunctionComponent<any>;
export declare type NumberProps = ControlProps<NumberValue | null> & NumberConfig;
export declare type NumberValue = number;
export declare type ObjectProps = ControlProps<ObjectValue> & ObjectConfig & {
    theme: any;
};
export declare type ObjectValue = any;
export declare type Options = OptionsArray | OptionsObject;
export declare type OptionsArray = any[];
export declare type OptionsControlType = "radio" | "inline-radio" | "check" | "inline-check" | "select" | "multi-select";
export declare type OptionsMultiSelection = any[];
export declare type OptionsObject = Record<string, any>;
export declare type OptionsProps = ControlProps<OptionsSelection> & OptionsConfig;
export declare type OptionsSelection = OptionsSingleSelection | OptionsMultiSelection;
export declare type OptionsSingleSelection = any;
export declare type PresetColor = ColorValue | {
    color: ColorValue;
    title?: string;
};
export declare type PropDefaultValue = PropSummaryValue;
export declare type PropType = PropSummaryValue;
export declare type RangeConfig = NumberConfig;
export declare type RangeProps = ControlProps<NumberValue | null> & RangeConfig;
export declare type Sizes = "100%" | "flex" | "auto";
export declare type SortType = "alpha" | "requiredFirst" | "none";
export declare type SourceProps = SourceErrorProps & SourceCodeProps;
export declare type StoryProps = InlineStoryProps | IFrameStoryProps;
export declare type SyntaxHighlighterFormatTypes = boolean | "dedent" | BuiltInParserName;
export declare type SyntaxHighlighterProps = SyntaxHighlighterBaseProps & SyntaxHighlighterCustomProps;
export declare type TextProps = ControlProps<TextValue | undefined> & TextConfig;
export declare type TextValue = string;
export declare type ValidationStates = "valid" | "error" | "warn";
export declare type ZoomProps = {
    scale: number;
    children: ReactElement | ReactElement[];
};
export declare type lineTagPropsFunction = (lineNumber: number) => React.HTMLProps<HTMLElement>;
export interface ActionBarProps {
    actionItems: ActionItem[];
}
export interface ActionItem {
    title: string | JSX.Element;
    className?: string;
    onClick: (e: MouseEvent<HTMLButtonElement>) => void;
    disabled?: boolean;
}
export interface AddonPanelProps {
    active: boolean;
    children: ReactNode;
}
export interface ArgType {
    name?: string;
    description?: string;
    defaultValue?: any;
    if?: Conditional;
    [key: string]: any;
}
export interface ArgTypes {
    [key: string]: ArgType;
}
export interface Args {
    [key: string]: any;
}
export interface ArgsTableDataProps {
    rows: ArgTypes;
    args?: Args;
    globals?: Globals;
}
export interface ArgsTableErrorProps {
    error: ArgsTableError;
}
export interface ArgsTableLoadingProps {
    isLoading: true;
}
export interface ArgsTableOptionProps {
    updateArgs?: (args: Args) => void;
    resetArgs?: (argNames?: string[]) => void;
    compact?: boolean;
    inAddonPanel?: boolean;
    initialExpandedArgs?: boolean;
    isLoading?: boolean;
    sort?: SortType;
}
export interface BadgeProps {
    status: "positive" | "negative" | "neutral" | "warning" | "critical";
}
export interface BarButtonProps extends DetailedHTMLProps<ButtonHTMLAttributes<HTMLButtonElement>, HTMLButtonElement> {
    href?: void;
}
export interface BarLinkProps extends DetailedHTMLProps<AnchorHTMLAttributes<HTMLAnchorElement>, HTMLAnchorElement> {
    href: string;
}
export interface BodyStyle {
    width: string;
    height: string;
    transform: string;
    transformOrigin: string;
}
export interface BooleanConfig {
}
export interface ButtonProps {
    isLink?: boolean;
    primary?: boolean;
    secondary?: boolean;
    tertiary?: boolean;
    gray?: boolean;
    inForm?: boolean;
    disabled?: boolean;
    small?: boolean;
    outline?: boolean;
    containsIcon?: boolean;
    children?: ReactNode;
    href?: string;
}
export interface ColorConfig {
    presetColors?: PresetColor[];
    startOpen?: boolean;
}
export interface ColorItemProps {
    title: string;
    subtitle: string;
    colors: Colors;
}
export interface CommonProps {
    title?: string;
    height?: string;
    id: string;
}
export interface ControlProps<T> {
    name: string;
    value?: T;
    defaultValue?: T;
    argType?: ArgType;
    onChange: (value: T) => T | void;
    onFocus?: (evt: any) => void;
    onBlur?: (evt: any) => void;
}
export interface DateConfig {
}
export interface DescriptionProps {
    markdown: string;
}
export interface DocsPageProps {
    title: string;
    subtitle?: string;
}
export interface FieldProps {
    label?: ReactNode;
}
export interface FilesControlProps extends ControlProps<string[]> {
    accept?: string;
}
export interface FlexBarProps {
    border?: boolean;
    children?: any;
    backgroundColor?: string;
}
export interface IFrameProps {
    id: string;
    key?: string;
    title: string;
    src: string;
    allowFullScreen: boolean;
    scale: number;
    style?: any;
}
export interface IconButtonProps {
    active?: boolean;
    disabled?: boolean;
}
export interface IconItemProps {
    name: string;
}
export interface IconsProps extends ComponentProps<typeof Svg> {
    icon?: IconKey;
    symbol?: IconKey;
}
export interface InlineStoryProps extends CommonProps {
    parameters: Parameters;
    storyFn: ElementType;
}
export interface InputStyleProps {
    size?: Sizes;
    align?: Alignments;
    valid?: ValidationStates;
    height?: number;
}
export interface ItemProps {
    disabled?: boolean;
}
export interface JsDocParam {
    name: string;
    description?: string;
}
export interface JsDocReturns {
    description?: string;
}
export interface JsDocTags {
    params?: JsDocParam[];
    returns?: JsDocReturns;
}
export interface Link extends Pick<ListItemProps, Exclude<keyof ListItemProps, "onClick">> {
    id: string;
    isGatsby?: boolean;
    onClick?: (event: SyntheticEvent, item: ListItemProps) => void;
}
export interface LinkInnerProps {
    withArrow?: boolean;
    containsIcon?: boolean;
}
export interface LinkProps extends LinkInnerProps, LinkStylesProps {
    cancel?: boolean;
    className?: string;
    style?: object;
    onClick?: (e: MouseEvent) => void;
    href?: string;
}
export interface LinkStylesProps {
    secondary?: boolean;
    tertiary?: boolean;
    nochrome?: boolean;
    inverse?: boolean;
    isButton?: boolean;
}
export interface ListItemProps extends Pick<ComponentProps<typeof Item>, Exclude<keyof ComponentProps<typeof Item>, "href" | "title">> {
    loading?: boolean;
    left?: ReactNode;
    title?: ReactNode;
    center?: ReactNode;
    right?: ReactNode;
    active?: boolean;
    disabled?: boolean;
    href?: string;
    LinkWrapper?: LinkWrapperType;
}
export interface LoaderProps {
    progress?: Progress;
    error?: Error;
    size?: number;
}
export interface NormalizedOptionsConfig {
    options: OptionsObject;
}
export interface NumberConfig {
    min?: number;
    max?: number;
    step?: number;
}
export interface ObjectConfig {
}
export interface OptionsConfig {
    labels: Record<any, string>;
    options: Options;
    type: OptionsControlType;
}
export interface PreviewProps {
    isLoading?: true;
    isColumn?: boolean;
    columns?: number;
    withSource?: SourceProps;
    isExpanded?: boolean;
    withToolbar?: boolean;
    className?: string;
    additionalActions?: ActionItem[];
}
export interface Progress {
    value: number;
    message: string;
    modules?: {
        complete: number;
        total: number;
    };
}
export interface PropSummaryValue {
    summary: string;
    detail?: string;
    required?: boolean;
}
export interface ScrollAreaProps {
    horizontal?: boolean;
    vertical?: boolean;
    className?: string;
}
export interface SeparatorProps {
    force?: boolean;
}
export interface SourceCodeProps {
    language?: string;
    code?: string;
    format?: ComponentProps<typeof SyntaxHighlighter>["format"];
    dark?: boolean;
}
export interface SourceErrorProps {
    isLoading?: boolean;
    error?: SourceError;
}
export interface SpacedProps {
    col?: number;
    row?: number;
    outer?: number | boolean;
}
export interface StorybookLogoProps {
    alt: string;
}
export interface SvgProps {
    inline?: boolean;
}
export interface SymbolsProps extends ComponentProps<typeof Svg> {
    icons?: IconKey[];
}
export interface SyntaxHighlighterBaseProps {
    language?: string;
    style?: any;
    customStyle?: any;
    lineProps?: lineTagPropsFunction | React.HTMLProps<HTMLElement>;
    codeTagProps?: React.HTMLProps<HTMLElement>;
    useInlineStyles?: boolean;
    showLineNumbers?: boolean;
    startingLineNumber?: number;
    lineNumberStyle?: any;
}
export interface SyntaxHighlighterCustomProps {
    language: string;
    copyable?: boolean;
    bordered?: boolean;
    padded?: boolean;
    format?: SyntaxHighlighterFormatTypes;
    formatter?: (type: SyntaxHighlighterFormatTypes, source: string) => string;
    className?: string;
    renderer?: (props: SyntaxHighlighterRendererProps) => ReactNode;
}
export interface SyntaxHighlighterRendererProps {
    rows: any[];
    stylesheet: string;
    useInlineStyles: boolean;
}
export interface TabButtonProps {
    active?: boolean;
    textColor?: string;
}
export interface TabWrapperProps {
    active: boolean;
    render?: () => JSX.Element;
    children?: ReactNode;
}
export interface TabbedArgsTableProps {
    tabs: Record<string, ArgsTableProps>;
    sort?: SortType;
}
export interface TableAnnotation {
    type: PropType;
    jsDocTags?: JsDocTags;
    defaultValue?: PropDefaultValue;
    category?: string;
}
export interface TabsProps {
    id?: string;
    tools?: ReactNode;
    selected?: string;
    actions?: {
        onSelect: (id: string) => void;
    } & Record<string, any>;
    backgroundColor?: string;
    absolute?: boolean;
    bordered?: boolean;
}
export interface TabsStateProps {
    children: (ReactNode | FuncChildren)[];
    initial: string;
    absolute: boolean;
    bordered: boolean;
    backgroundColor: string;
}
export interface TabsStateState {
    selected: string;
}
export interface TextConfig {
}
export interface TooltipLinkListProps {
    links: Link[];
    LinkWrapper?: LinkWrapperType;
}
export interface TooltipMessageProps {
    title?: ReactNode;
    desc?: ReactNode;
    links?: {
        title: string;
        href?: string;
        onClick?: () => void;
    }[];
}
export interface TooltipNoteProps {
    note: string;
}
export interface TypesetProps {
    fontFamily?: string;
    fontSizes: string[];
    fontWeight?: number;
    sampleText?: string;
}
export interface WithHideFn {
    onHide: () => void;
}
export interface WithTooltipPureProps {
    svg?: boolean;
    trigger?: "none" | "hover" | "click" | "right-click";
    closeOnClick?: boolean;
    placement?: Placement;
    modifiers?: Array<Partial<Modifier<string, {}>>>;
    hasChrome?: boolean;
    tooltip: ReactNode | ((p: WithHideFn) => ReactNode);
    children: ReactNode;
    tooltipShown?: boolean;
    onVisibilityChange?: (visibility: boolean) => void | boolean;
    onDoubleClick?: () => void;
}
export {};
