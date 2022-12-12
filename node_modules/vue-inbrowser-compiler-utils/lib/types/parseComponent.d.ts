interface VsgSFCDescriptorSimple {
    template?: string;
    script?: string;
}
export interface VsgSFCDescriptor extends VsgSFCDescriptorSimple {
    styles?: string[];
}
export default function parseComponent(code: string): VsgSFCDescriptor;
export {};
