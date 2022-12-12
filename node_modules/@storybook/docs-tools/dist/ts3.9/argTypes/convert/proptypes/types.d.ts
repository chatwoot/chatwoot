interface PTBaseType {
    name: string;
    description?: string;
    required?: boolean;
}
export declare type PTType = PTBaseType & {
    value?: any;
    raw?: string;
    computed?: boolean;
};
export {};
