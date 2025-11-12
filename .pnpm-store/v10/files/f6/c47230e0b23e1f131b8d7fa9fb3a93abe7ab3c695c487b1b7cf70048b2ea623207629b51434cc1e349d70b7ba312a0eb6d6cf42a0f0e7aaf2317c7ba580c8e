import { PropType } from "vue";
export interface ChunkOptions {
    headers: {
        [key: string]: any;
    };
    action: string;
    minSize: number;
    maxActive: number;
    maxRetries: number;
    handler: any;
}
export interface Data {
    active: boolean;
    dropActive: boolean;
    dropElementActive: boolean;
    files: VueUploadItem[];
    maps: {
        [key: string]: VueUploadItem;
    };
    destroy: boolean;
    uploading: number;
    features: Features;
    dropElement: null | HTMLElement;
    dropTimeout: null | number;
    reload: boolean;
}
export interface Features {
    html5: boolean;
    directory: boolean;
    drop: boolean;
}
export interface VueUploadItem {
    id: string;
    readonly fileObject?: boolean;
    name?: string;
    size?: number;
    type?: string;
    active?: boolean;
    error?: Error | string;
    success?: boolean;
    postAction?: string;
    putAction?: string;
    timeout?: number;
    data?: {
        [key: string]: any;
    };
    headers?: {
        [key: string]: any;
    };
    response?: {
        [key: string]: any;
    };
    progress?: string;
    speed?: 0;
    file?: Blob;
    xhr?: XMLHttpRequest;
    el?: HTMLInputElement;
    iframe?: HTMLElement;
    [key: string]: any;
}
declare const _default: import("vue").DefineComponent<{
    inputId: {
        type: StringConstructor;
    };
    name: {
        type: StringConstructor;
        default: string;
    };
    accept: {
        type: StringConstructor;
    };
    capture: {};
    disabled: {
        default: boolean;
    };
    multiple: {
        type: BooleanConstructor;
        default: boolean;
    };
    maximum: {
        type: NumberConstructor;
    };
    addIndex: {
        type: (BooleanConstructor | NumberConstructor)[];
    };
    directory: {
        type: BooleanConstructor;
    };
    createDirectory: {
        type: BooleanConstructor;
        default: boolean;
    };
    postAction: {
        type: StringConstructor;
    };
    putAction: {
        type: StringConstructor;
    };
    customAction: {
        type: PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
    };
    headers: {
        type: PropType<{
            [key: string]: any;
        }>;
        default: () => {};
    };
    data: {
        type: PropType<{
            [key: string]: any;
        }>;
        default: () => {};
    };
    timeout: {
        type: NumberConstructor;
        default: number;
    };
    drop: {
        type: PropType<string | boolean | HTMLElement | null>;
        default: () => boolean;
    };
    dropDirectory: {
        type: BooleanConstructor;
        default: boolean;
    };
    size: {
        type: NumberConstructor;
        default: number;
    };
    extensions: {
        type: PropType<string | RegExp | string[]>;
        default: () => never[];
    };
    modelValue: {
        type: PropType<VueUploadItem[]>;
        default: () => never[];
    };
    thread: {
        type: NumberConstructor;
        default: number;
    };
    chunkEnabled: {
        type: BooleanConstructor;
        default: boolean;
    };
    chunk: {
        type: PropType<{
            headers?: {
                [key: string]: any;
            } | undefined;
            action?: string | undefined;
            minSize?: number | undefined;
            maxActive?: number | undefined;
            maxRetries?: number | undefined;
            handler?: any;
        }>;
        default: () => ChunkOptions;
    };
}, unknown, Data, {
    /**
     * uploading 正在上传的线程
     * @return {[type]} [description]
     */
    /**
     * uploaded 文件列表是否全部已上传
     * @return {[type]} [description]
     */
    uploaded(): boolean;
    chunkOptions(): ChunkOptions;
    className(): Array<string | undefined>;
    forId(): string;
    iMaximum(): number;
    iExtensions(): RegExp | undefined;
    iDirectory(): any;
}, {
    newId(): string;
    clear(): true;
    get(id: string | VueUploadItem): VueUploadItem | false;
    add(_files: VueUploadItem | Blob | Array<VueUploadItem | Blob>, index?: number | boolean | undefined): VueUploadItem | VueUploadItem[] | undefined;
    addInputFile(el: HTMLInputElement): Promise<VueUploadItem[]>;
    addDataTransfer(dataTransfer: DataTransfer): Promise<VueUploadItem[] | undefined>;
    getFileSystemEntry(entry: Array<File | FileSystemEntry> | File | FileSystemEntry, path?: string): Promise<VueUploadItem[]>;
    replace(id1: VueUploadItem | string, id2: VueUploadItem | string): boolean;
    remove(id: VueUploadItem | string): VueUploadItem | false;
    update(id: VueUploadItem | string, data: {
        [key: string]: any;
    }): VueUploadItem | false;
    emitFilter(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): boolean;
    emitFile(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): void;
    emitInput(): void;
    upload(id: VueUploadItem | string): Promise<VueUploadItem>;
    /**
     * Whether this file should be uploaded using chunk upload or not
     *
     * @param Object file
     */
    shouldUseChunkUpload(file: VueUploadItem): boolean | 0 | undefined;
    /**
     * Upload a file using Chunk method
     *
     * @param File file
     */
    uploadChunk(file: VueUploadItem): Promise<VueUploadItem>;
    uploadPut(file: VueUploadItem): Promise<VueUploadItem>;
    uploadHtml5(file: VueUploadItem): Promise<VueUploadItem>;
    uploadXhr(xhr: XMLHttpRequest, ufile: VueUploadItem | undefined | false, body: FormData | Blob): Promise<VueUploadItem>;
    uploadHtml4(ufile: VueUploadItem | undefined | false): Promise<VueUploadItem>;
    watchActive(active: boolean): void;
    watchDrop(newDrop: boolean | string | HTMLElement | null, oldDrop?: boolean | string | HTMLElement | undefined): void;
    watchDropActive(newDropActive: boolean, oldDropActive?: boolean | undefined): void;
    onDocumentDragenter(e: DragEvent): void;
    onDocumentDragleave(e: DragEvent): void;
    onDocumentDragover(): void;
    onDocumentDrop(): void;
    onDragenter(e: DragEvent): void;
    onDragleave(e: DragEvent): void;
    onDragover(e: DragEvent): void;
    onDrop(e: DragEvent): void;
    inputOnChange(e: Event): Promise<any>;
    isRelatedTargetSupported(): boolean;
}, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, ("update:modelValue" | "input-filter" | "input-file")[], "update:modelValue" | "input-filter" | "input-file", import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<import("vue").ExtractPropTypes<{
    inputId: {
        type: StringConstructor;
    };
    name: {
        type: StringConstructor;
        default: string;
    };
    accept: {
        type: StringConstructor;
    };
    capture: {};
    disabled: {
        default: boolean;
    };
    multiple: {
        type: BooleanConstructor;
        default: boolean;
    };
    maximum: {
        type: NumberConstructor;
    };
    addIndex: {
        type: (BooleanConstructor | NumberConstructor)[];
    };
    directory: {
        type: BooleanConstructor;
    };
    createDirectory: {
        type: BooleanConstructor;
        default: boolean;
    };
    postAction: {
        type: StringConstructor;
    };
    putAction: {
        type: StringConstructor;
    };
    customAction: {
        type: PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
    };
    headers: {
        type: PropType<{
            [key: string]: any;
        }>;
        default: () => {};
    };
    data: {
        type: PropType<{
            [key: string]: any;
        }>;
        default: () => {};
    };
    timeout: {
        type: NumberConstructor;
        default: number;
    };
    drop: {
        type: PropType<string | boolean | HTMLElement | null>;
        default: () => boolean;
    };
    dropDirectory: {
        type: BooleanConstructor;
        default: boolean;
    };
    size: {
        type: NumberConstructor;
        default: number;
    };
    extensions: {
        type: PropType<string | RegExp | string[]>;
        default: () => never[];
    };
    modelValue: {
        type: PropType<VueUploadItem[]>;
        default: () => never[];
    };
    thread: {
        type: NumberConstructor;
        default: number;
    };
    chunkEnabled: {
        type: BooleanConstructor;
        default: boolean;
    };
    chunk: {
        type: PropType<{
            headers?: {
                [key: string]: any;
            } | undefined;
            action?: string | undefined;
            minSize?: number | undefined;
            maxActive?: number | undefined;
            maxRetries?: number | undefined;
            handler?: any;
        }>;
        default: () => ChunkOptions;
    };
}>> & {
    "onUpdate:modelValue"?: ((...args: any[]) => any) | undefined;
    "onInput-filter"?: ((...args: any[]) => any) | undefined;
    "onInput-file"?: ((...args: any[]) => any) | undefined;
}, {
    name: string;
    size: number;
    timeout: number;
    data: {
        [key: string]: any;
    };
    headers: {
        [key: string]: any;
    };
    drop: string | boolean | HTMLElement | null;
    modelValue: VueUploadItem[];
    disabled: boolean;
    multiple: boolean;
    directory: boolean;
    createDirectory: boolean;
    dropDirectory: boolean;
    extensions: string | RegExp | string[];
    thread: number;
    chunkEnabled: boolean;
    chunk: {
        headers?: {
            [key: string]: any;
        } | undefined;
        action?: string | undefined;
        minSize?: number | undefined;
        maxActive?: number | undefined;
        maxRetries?: number | undefined;
        handler?: any;
    };
}>;
export default _default;
