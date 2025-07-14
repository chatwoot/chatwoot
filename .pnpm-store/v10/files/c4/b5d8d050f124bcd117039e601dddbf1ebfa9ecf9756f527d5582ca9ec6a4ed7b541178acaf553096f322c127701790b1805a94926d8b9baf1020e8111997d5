/// <reference types="node" />
import { SetupContext } from 'vue';
import type { VueUploadItem } from '../../../src/FileUpload.vue';
declare const _default: {
    components: {
        FileUpload: import("vue").DefineComponent<{
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
                type: import("vue").PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
            };
            headers: {
                type: import("vue").PropType<{
                    [key: string]: any;
                }>;
                default: () => {};
            };
            data: {
                type: import("vue").PropType<{
                    [key: string]: any;
                }>;
                default: () => {};
            };
            timeout: {
                type: NumberConstructor;
                default: number;
            };
            drop: {
                default: boolean;
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
                type: import("vue").PropType<string | RegExp | string[]>;
                default: () => never[];
            };
            modelValue: {
                type: import("vue").PropType<VueUploadItem[]>;
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
                type: import("vue").PropType<{
                    headers?: {
                        [key: string]: any;
                    } | undefined;
                    action?: string | undefined;
                    minSize?: number | undefined;
                    maxActive?: number | undefined;
                    maxRetries?: number | undefined;
                    handler?: any;
                }>;
                default: () => import("../../../src/FileUpload.vue").ChunkOptions;
            };
        }, unknown, import("../../../src/FileUpload.vue").Data, {
            uploaded(): boolean;
            chunkOptions(): import("../../../src/FileUpload.vue").ChunkOptions;
            className(): (string | undefined)[];
            forId(): string;
            iMaximum(): number;
            iExtensions(): RegExp | undefined;
        }, {
            newId(): string;
            clear(): true;
            get(id: string | VueUploadItem): false | VueUploadItem;
            add(_files: VueUploadItem | Blob | (VueUploadItem | Blob)[], index?: number | boolean | undefined): VueUploadItem | VueUploadItem[] | undefined;
            addInputFile(el: HTMLInputElement): Promise<VueUploadItem[]>;
            addDataTransfer(dataTransfer: DataTransfer): Promise<VueUploadItem[] | undefined>;
            getFileSystemEntry(entry: any, path?: string): Promise<VueUploadItem[]>;
            replace(id1: string | VueUploadItem, id2: string | VueUploadItem): boolean;
            remove(id: string | VueUploadItem): false | VueUploadItem;
            update(id: string | VueUploadItem, data: {
                [key: string]: any;
            }): false | VueUploadItem;
            emitFilter(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): boolean;
            emitFile(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): void;
            emitInput(): void;
            upload(id: string | VueUploadItem): Promise<VueUploadItem>;
            shouldUseChunkUpload(file: VueUploadItem): boolean | 0 | undefined;
            uploadChunk(file: VueUploadItem): Promise<VueUploadItem>;
            uploadPut(file: VueUploadItem): Promise<VueUploadItem>;
            uploadHtml5(file: VueUploadItem): Promise<VueUploadItem>;
            uploadXhr(xhr: XMLHttpRequest, ufile: false | VueUploadItem | undefined, body: Blob | FormData): Promise<VueUploadItem>;
            uploadHtml4(ufile: false | VueUploadItem | undefined): Promise<VueUploadItem>;
            watchActive(active: boolean): void;
            watchDrop(newDrop: string | boolean | HTMLElement | null, oldDrop?: string | boolean | HTMLElement | undefined): void;
            onDragenter(e: DragEvent): void;
            onDragleave(e: DragEvent): void;
            onDragover(e: DragEvent): void;
            onDocumentDrop(): void;
            onDrop(e: DragEvent): void;
            inputOnChange(e: Event): Promise<any>;
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
                type: import("vue").PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
            };
            headers: {
                type: import("vue").PropType<{
                    [key: string]: any;
                }>;
                default: () => {};
            };
            data: {
                type: import("vue").PropType<{
                    [key: string]: any;
                }>;
                default: () => {};
            };
            timeout: {
                type: NumberConstructor;
                default: number;
            };
            drop: {
                default: boolean;
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
                type: import("vue").PropType<string | RegExp | string[]>;
                default: () => never[];
            };
            modelValue: {
                type: import("vue").PropType<VueUploadItem[]>;
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
                type: import("vue").PropType<{
                    headers?: {
                        [key: string]: any;
                    } | undefined;
                    action?: string | undefined;
                    minSize?: number | undefined;
                    maxActive?: number | undefined;
                    maxRetries?: number | undefined;
                    handler?: any;
                }>;
                default: () => import("../../../src/FileUpload.vue").ChunkOptions;
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
            drop: boolean;
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
    };
    setup(props: unknown, context: SetupContext): {
        files: import("vue").Ref<never[]>;
        upload: import("vue").Ref<({
            $: import("vue").ComponentInternalInstance;
            $data: import("../../../src/FileUpload.vue").Data;
            $props: Partial<{
                name: string;
                size: number;
                timeout: number;
                data: {
                    [key: string]: any;
                };
                headers: {
                    [key: string]: any;
                };
                drop: boolean;
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
            }> & Omit<Readonly<import("vue").ExtractPropTypes<{
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
                    type: import("vue").PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
                };
                headers: {
                    type: import("vue").PropType<{
                        [key: string]: any;
                    }>;
                    default: () => {};
                };
                data: {
                    type: import("vue").PropType<{
                        [key: string]: any;
                    }>;
                    default: () => {};
                };
                timeout: {
                    type: NumberConstructor;
                    default: number;
                };
                drop: {
                    default: boolean;
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
                    type: import("vue").PropType<string | RegExp | string[]>;
                    default: () => never[];
                };
                modelValue: {
                    type: import("vue").PropType<VueUploadItem[]>;
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
                    type: import("vue").PropType<{
                        headers?: {
                            [key: string]: any;
                        } | undefined;
                        action?: string | undefined;
                        minSize?: number | undefined;
                        maxActive?: number | undefined;
                        maxRetries?: number | undefined;
                        handler?: any;
                    }>;
                    default: () => import("../../../src/FileUpload.vue").ChunkOptions;
                };
            }>> & {
                "onUpdate:modelValue"?: ((...args: any[]) => any) | undefined;
                "onInput-filter"?: ((...args: any[]) => any) | undefined;
                "onInput-file"?: ((...args: any[]) => any) | undefined;
            } & import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, "name" | "size" | "timeout" | "data" | "headers" | "drop" | "modelValue" | "disabled" | "multiple" | "directory" | "createDirectory" | "dropDirectory" | "extensions" | "thread" | "chunkEnabled" | "chunk">;
            $attrs: {
                [x: string]: unknown;
            };
            $refs: {
                [x: string]: unknown;
            };
            $slots: Readonly<{
                [name: string]: import("vue").Slot | undefined;
            }>;
            $root: import("vue").ComponentPublicInstance<{}, {}, {}, {}, {}, {}, {}, {}, false, import("vue").ComponentOptionsBase<any, any, any, any, any, any, any, any, any, {}>> | null;
            $parent: import("vue").ComponentPublicInstance<{}, {}, {}, {}, {}, {}, {}, {}, false, import("vue").ComponentOptionsBase<any, any, any, any, any, any, any, any, any, {}>> | null;
            $emit: (event: "update:modelValue" | "input-filter" | "input-file", ...args: any[]) => void;
            $el: any;
            $options: import("vue").ComponentOptionsBase<Readonly<import("vue").ExtractPropTypes<{
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
                    type: import("vue").PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
                };
                headers: {
                    type: import("vue").PropType<{
                        [key: string]: any;
                    }>;
                    default: () => {};
                };
                data: {
                    type: import("vue").PropType<{
                        [key: string]: any;
                    }>;
                    default: () => {};
                };
                timeout: {
                    type: NumberConstructor;
                    default: number;
                };
                drop: {
                    default: boolean;
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
                    type: import("vue").PropType<string | RegExp | string[]>;
                    default: () => never[];
                };
                modelValue: {
                    type: import("vue").PropType<VueUploadItem[]>;
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
                    type: import("vue").PropType<{
                        headers?: {
                            [key: string]: any;
                        } | undefined;
                        action?: string | undefined;
                        minSize?: number | undefined;
                        maxActive?: number | undefined;
                        maxRetries?: number | undefined;
                        handler?: any;
                    }>;
                    default: () => import("../../../src/FileUpload.vue").ChunkOptions;
                };
            }>> & {
                "onUpdate:modelValue"?: ((...args: any[]) => any) | undefined;
                "onInput-filter"?: ((...args: any[]) => any) | undefined;
                "onInput-file"?: ((...args: any[]) => any) | undefined;
            }, unknown, import("../../../src/FileUpload.vue").Data, {
                uploaded(): boolean;
                chunkOptions(): import("../../../src/FileUpload.vue").ChunkOptions;
                className(): (string | undefined)[];
                forId(): string;
                iMaximum(): number;
                iExtensions(): RegExp | undefined;
            }, {
                newId(): string;
                clear(): true;
                get(id: string | VueUploadItem): false | VueUploadItem;
                add(_files: VueUploadItem | Blob | (VueUploadItem | Blob)[], index?: number | boolean | undefined): VueUploadItem | VueUploadItem[] | undefined;
                addInputFile(el: HTMLInputElement): Promise<VueUploadItem[]>;
                addDataTransfer(dataTransfer: DataTransfer): Promise<VueUploadItem[] | undefined>;
                getFileSystemEntry(entry: any, path?: string): Promise<VueUploadItem[]>;
                replace(id1: string | VueUploadItem, id2: string | VueUploadItem): boolean;
                remove(id: string | VueUploadItem): false | VueUploadItem;
                update(id: string | VueUploadItem, data: {
                    [key: string]: any;
                }): false | VueUploadItem;
                emitFilter(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): boolean;
                emitFile(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): void;
                emitInput(): void;
                upload(id: string | VueUploadItem): Promise<VueUploadItem>;
                shouldUseChunkUpload(file: VueUploadItem): boolean | 0 | undefined;
                uploadChunk(file: VueUploadItem): Promise<VueUploadItem>;
                uploadPut(file: VueUploadItem): Promise<VueUploadItem>;
                uploadHtml5(file: VueUploadItem): Promise<VueUploadItem>;
                uploadXhr(xhr: XMLHttpRequest, ufile: false | VueUploadItem | undefined, body: Blob | FormData): Promise<VueUploadItem>;
                uploadHtml4(ufile: false | VueUploadItem | undefined): Promise<VueUploadItem>;
                watchActive(active: boolean): void;
                watchDrop(newDrop: string | boolean | HTMLElement | null, oldDrop?: string | boolean | HTMLElement | undefined): void;
                onDragenter(e: DragEvent): void;
                onDragleave(e: DragEvent): void;
                onDragover(e: DragEvent): void;
                onDocumentDrop(): void;
                onDrop(e: DragEvent): void;
                inputOnChange(e: Event): Promise<any>;
            }, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, ("update:modelValue" | "input-filter" | "input-file")[], string, {
                name: string;
                size: number;
                timeout: number;
                data: {
                    [key: string]: any;
                };
                headers: {
                    [key: string]: any;
                };
                drop: boolean;
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
            }> & {
                beforeCreate?: ((() => void) | (() => void)[]) | undefined;
                created?: ((() => void) | (() => void)[]) | undefined;
                beforeMount?: ((() => void) | (() => void)[]) | undefined;
                mounted?: ((() => void) | (() => void)[]) | undefined;
                beforeUpdate?: ((() => void) | (() => void)[]) | undefined;
                updated?: ((() => void) | (() => void)[]) | undefined;
                activated?: ((() => void) | (() => void)[]) | undefined;
                deactivated?: ((() => void) | (() => void)[]) | undefined;
                beforeDestroy?: ((() => void) | (() => void)[]) | undefined;
                beforeUnmount?: ((() => void) | (() => void)[]) | undefined;
                destroyed?: ((() => void) | (() => void)[]) | undefined;
                unmounted?: ((() => void) | (() => void)[]) | undefined;
                renderTracked?: (((e: import("vue").DebuggerEvent) => void) | ((e: import("vue").DebuggerEvent) => void)[]) | undefined;
                renderTriggered?: (((e: import("vue").DebuggerEvent) => void) | ((e: import("vue").DebuggerEvent) => void)[]) | undefined;
                errorCaptured?: (((err: unknown, instance: import("vue").ComponentPublicInstance<{}, {}, {}, {}, {}, {}, {}, {}, false, import("vue").ComponentOptionsBase<any, any, any, any, any, any, any, any, any, {}>> | null, info: string) => boolean | void) | ((err: unknown, instance: import("vue").ComponentPublicInstance<{}, {}, {}, {}, {}, {}, {}, {}, false, import("vue").ComponentOptionsBase<any, any, any, any, any, any, any, any, any, {}>> | null, info: string) => boolean | void)[]) | undefined;
            };
            $forceUpdate: () => void;
            $nextTick: typeof import("vue").nextTick;
            $watch(source: string | Function, cb: Function, options?: import("vue").WatchOptions<boolean> | undefined): import("vue").WatchStopHandle;
        } & Readonly<import("vue").ExtractPropTypes<{
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
                type: import("vue").PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>;
            };
            headers: {
                type: import("vue").PropType<{
                    [key: string]: any;
                }>;
                default: () => {};
            };
            data: {
                type: import("vue").PropType<{
                    [key: string]: any;
                }>;
                default: () => {};
            };
            timeout: {
                type: NumberConstructor;
                default: number;
            };
            drop: {
                default: boolean;
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
                type: import("vue").PropType<string | RegExp | string[]>;
                default: () => never[];
            };
            modelValue: {
                type: import("vue").PropType<VueUploadItem[]>;
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
                type: import("vue").PropType<{
                    headers?: {
                        [key: string]: any;
                    } | undefined;
                    action?: string | undefined;
                    minSize?: number | undefined;
                    maxActive?: number | undefined;
                    maxRetries?: number | undefined;
                    handler?: any;
                }>;
                default: () => import("../../../src/FileUpload.vue").ChunkOptions;
            };
        }>> & {
            "onUpdate:modelValue"?: ((...args: any[]) => any) | undefined;
            "onInput-filter"?: ((...args: any[]) => any) | undefined;
            "onInput-file"?: ((...args: any[]) => any) | undefined;
        } & import("vue").ShallowUnwrapRef<{}> & {
            active: boolean;
            dropActive: boolean;
            files: {
                [x: string]: any;
                id: string;
                readonly fileObject?: boolean | undefined;
                name?: string | undefined;
                size?: number | undefined;
                type?: string | undefined;
                active?: boolean | undefined;
                error?: string | {
                    name: string;
                    message: string;
                    stack?: string | undefined;
                } | undefined;
                success?: boolean | undefined;
                postAction?: string | undefined;
                putAction?: string | undefined;
                timeout?: number | undefined;
                data?: {
                    [x: string]: any;
                } | undefined;
                headers?: {
                    [x: string]: any;
                } | undefined;
                response?: {
                    [x: string]: any;
                } | undefined;
                progress?: string | undefined;
                speed?: 0 | undefined;
                file?: {
                    readonly size: number;
                    readonly type: string;
                    arrayBuffer: {
                        (): Promise<ArrayBuffer>;
                        (): Promise<ArrayBuffer>;
                    };
                    slice: {
                        (start?: number | undefined, end?: number | undefined, contentType?: string | undefined): Blob;
                        (start?: number | undefined, end?: number | undefined, contentType?: string | undefined): Blob;
                    };
                    stream: {
                        (): NodeJS.ReadableStream;
                        (): ReadableStream<any>;
                    };
                    text: {
                        (): Promise<string>;
                        (): Promise<string>;
                    };
                } | undefined;
                xhr?: {
                    onreadystatechange: ((this: XMLHttpRequest, ev: Event) => any) | null;
                    readonly readyState: number;
                    readonly response: any;
                    readonly responseText: string;
                    responseType: XMLHttpRequestResponseType;
                    readonly responseURL: string;
                    readonly responseXML: Document | null;
                    readonly status: number;
                    readonly statusText: string;
                    timeout: number;
                    readonly upload: {
                        addEventListener: {
                            <K extends keyof XMLHttpRequestEventTargetEventMap>(type: K, listener: (this: XMLHttpRequestUpload, ev: XMLHttpRequestEventTargetEventMap[K]) => any, options?: boolean | AddEventListenerOptions | undefined): void;
                            (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions | undefined): void;
                        };
                        removeEventListener: {
                            <K_1 extends keyof XMLHttpRequestEventTargetEventMap>(type: K_1, listener: (this: XMLHttpRequestUpload, ev: XMLHttpRequestEventTargetEventMap[K_1]) => any, options?: boolean | EventListenerOptions | undefined): void;
                            (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions | undefined): void;
                        };
                        onabort: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onerror: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onload: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onloadend: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onloadstart: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onprogress: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        ontimeout: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        dispatchEvent: (event: Event) => boolean;
                    };
                    withCredentials: boolean;
                    abort: () => void;
                    getAllResponseHeaders: () => string;
                    getResponseHeader: (name: string) => string | null;
                    open: {
                        (method: string, url: string | URL): void;
                        (method: string, url: string | URL, async: boolean, username?: string | null | undefined, password?: string | null | undefined): void;
                    };
                    overrideMimeType: (mime: string) => void;
                    send: (body?: Document | XMLHttpRequestBodyInit | null | undefined) => void;
                    setRequestHeader: (name: string, value: string) => void;
                    readonly DONE: number;
                    readonly HEADERS_RECEIVED: number;
                    readonly LOADING: number;
                    readonly OPENED: number;
                    readonly UNSENT: number;
                    addEventListener: {
                        <K_2 extends keyof XMLHttpRequestEventMap>(type: K_2, listener: (this: XMLHttpRequest, ev: XMLHttpRequestEventMap[K_2]) => any, options?: boolean | AddEventListenerOptions | undefined): void;
                        (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions | undefined): void;
                    };
                    removeEventListener: {
                        <K_3 extends keyof XMLHttpRequestEventMap>(type: K_3, listener: (this: XMLHttpRequest, ev: XMLHttpRequestEventMap[K_3]) => any, options?: boolean | EventListenerOptions | undefined): void;
                        (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions | undefined): void;
                    };
                    onabort: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    onerror: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    onload: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    onloadend: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    onloadstart: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    onprogress: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    ontimeout: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                    dispatchEvent: (event: Event) => boolean;
                } | undefined;
                el?: HTMLInputElement | undefined;
                iframe?: HTMLElement | undefined;
            }[];
            maps: {
                [x: string]: {
                    [x: string]: any;
                    id: string;
                    readonly fileObject?: boolean | undefined;
                    name?: string | undefined;
                    size?: number | undefined;
                    type?: string | undefined;
                    active?: boolean | undefined;
                    error?: string | {
                        name: string;
                        message: string;
                        stack?: string | undefined;
                    } | undefined;
                    success?: boolean | undefined;
                    postAction?: string | undefined;
                    putAction?: string | undefined;
                    timeout?: number | undefined;
                    data?: {
                        [x: string]: any;
                    } | undefined;
                    headers?: {
                        [x: string]: any;
                    } | undefined;
                    response?: {
                        [x: string]: any;
                    } | undefined;
                    progress?: string | undefined;
                    speed?: 0 | undefined;
                    file?: {
                        readonly size: number;
                        readonly type: string;
                        arrayBuffer: {
                            (): Promise<ArrayBuffer>;
                            (): Promise<ArrayBuffer>;
                        };
                        slice: {
                            (start?: number | undefined, end?: number | undefined, contentType?: string | undefined): Blob;
                            (start?: number | undefined, end?: number | undefined, contentType?: string | undefined): Blob;
                        };
                        stream: {
                            (): NodeJS.ReadableStream;
                            (): ReadableStream<any>;
                        };
                        text: {
                            (): Promise<string>;
                            (): Promise<string>;
                        };
                    } | undefined;
                    xhr?: {
                        onreadystatechange: ((this: XMLHttpRequest, ev: Event) => any) | null;
                        readonly readyState: number;
                        readonly response: any;
                        readonly responseText: string;
                        responseType: XMLHttpRequestResponseType;
                        readonly responseURL: string;
                        readonly responseXML: Document | null;
                        readonly status: number;
                        readonly statusText: string;
                        timeout: number;
                        readonly upload: {
                            addEventListener: {
                                <K extends keyof XMLHttpRequestEventTargetEventMap>(type: K, listener: (this: XMLHttpRequestUpload, ev: XMLHttpRequestEventTargetEventMap[K]) => any, options?: boolean | AddEventListenerOptions | undefined): void;
                                (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions | undefined): void;
                            };
                            removeEventListener: {
                                <K_1 extends keyof XMLHttpRequestEventTargetEventMap>(type: K_1, listener: (this: XMLHttpRequestUpload, ev: XMLHttpRequestEventTargetEventMap[K_1]) => any, options?: boolean | EventListenerOptions | undefined): void;
                                (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions | undefined): void;
                            };
                            onabort: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            onerror: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            onload: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            onloadend: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            onloadstart: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            onprogress: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            ontimeout: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                            dispatchEvent: (event: Event) => boolean;
                        };
                        withCredentials: boolean;
                        abort: () => void;
                        getAllResponseHeaders: () => string;
                        getResponseHeader: (name: string) => string | null;
                        open: {
                            (method: string, url: string | URL): void;
                            (method: string, url: string | URL, async: boolean, username?: string | null | undefined, password?: string | null | undefined): void;
                        };
                        overrideMimeType: (mime: string) => void;
                        send: (body?: Document | XMLHttpRequestBodyInit | null | undefined) => void;
                        setRequestHeader: (name: string, value: string) => void;
                        readonly DONE: number;
                        readonly HEADERS_RECEIVED: number;
                        readonly LOADING: number;
                        readonly OPENED: number;
                        readonly UNSENT: number;
                        addEventListener: {
                            <K_2 extends keyof XMLHttpRequestEventMap>(type: K_2, listener: (this: XMLHttpRequest, ev: XMLHttpRequestEventMap[K_2]) => any, options?: boolean | AddEventListenerOptions | undefined): void;
                            (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | AddEventListenerOptions | undefined): void;
                        };
                        removeEventListener: {
                            <K_3 extends keyof XMLHttpRequestEventMap>(type: K_3, listener: (this: XMLHttpRequest, ev: XMLHttpRequestEventMap[K_3]) => any, options?: boolean | EventListenerOptions | undefined): void;
                            (type: string, listener: EventListenerOrEventListenerObject, options?: boolean | EventListenerOptions | undefined): void;
                        };
                        onabort: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onerror: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onload: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onloadend: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onloadstart: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        onprogress: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        ontimeout: ((this: XMLHttpRequest, ev: ProgressEvent<EventTarget>) => any) | null;
                        dispatchEvent: (event: Event) => boolean;
                    } | undefined;
                    el?: HTMLInputElement | undefined;
                    iframe?: HTMLElement | undefined;
                };
            };
            destroy: boolean;
            uploading: number;
            features: {
                html5: boolean;
                directory: boolean;
                drop: boolean;
            };
            dropElement: HTMLElement | null;
            reload: boolean;
        } & {
            uploaded: boolean;
            chunkOptions: import("../../../src/FileUpload.vue").ChunkOptions;
            className: (string | undefined)[];
            forId: string;
            iMaximum: number;
            iExtensions: RegExp | undefined;
        } & {
            newId(): string;
            clear(): true;
            get(id: string | VueUploadItem): false | VueUploadItem;
            add(_files: VueUploadItem | Blob | (VueUploadItem | Blob)[], index?: number | boolean | undefined): VueUploadItem | VueUploadItem[] | undefined;
            addInputFile(el: HTMLInputElement): Promise<VueUploadItem[]>;
            addDataTransfer(dataTransfer: DataTransfer): Promise<VueUploadItem[] | undefined>;
            getFileSystemEntry(entry: any, path?: string): Promise<VueUploadItem[]>;
            replace(id1: string | VueUploadItem, id2: string | VueUploadItem): boolean;
            remove(id: string | VueUploadItem): false | VueUploadItem;
            update(id: string | VueUploadItem, data: {
                [key: string]: any;
            }): false | VueUploadItem;
            emitFilter(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): boolean;
            emitFile(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): void;
            emitInput(): void;
            upload(id: string | VueUploadItem): Promise<VueUploadItem>;
            shouldUseChunkUpload(file: VueUploadItem): boolean | 0 | undefined;
            uploadChunk(file: VueUploadItem): Promise<VueUploadItem>;
            uploadPut(file: VueUploadItem): Promise<VueUploadItem>;
            uploadHtml5(file: VueUploadItem): Promise<VueUploadItem>;
            uploadXhr(xhr: XMLHttpRequest, ufile: false | VueUploadItem | undefined, body: Blob | FormData): Promise<VueUploadItem>;
            uploadHtml4(ufile: false | VueUploadItem | undefined): Promise<VueUploadItem>;
            watchActive(active: boolean): void;
            watchDrop(newDrop: string | boolean | HTMLElement | null, oldDrop?: string | boolean | HTMLElement | undefined): void;
            onDragenter(e: DragEvent): void;
            onDragleave(e: DragEvent): void;
            onDragover(e: DragEvent): void;
            onDocumentDrop(): void;
            onDrop(e: DragEvent): void;
            inputOnChange(e: Event): Promise<any>;
        } & import("vue").ComponentCustomProperties) | null>;
        inputFilter: (newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined, prevent: (prevent?: boolean | undefined) => boolean) => boolean | undefined;
        inputFile: (newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined) => void;
    };
};
export default _default;
