type TreeNode = {
    [key: string]: string | number | boolean | CSSStyleDeclaration | TreeNode | Node;
} & {
    xmlns?: string;
    style?: Partial<CSSStyleDeclaration>;
    textContent?: string | Node;
    children?: TreeNode;
};
export declare function createElement(tagName: string, content: TreeNode & {
    xmlns: string;
}, container?: Node): SVGElement;
export declare function createElement(tagName: string, content?: TreeNode, container?: Node): HTMLElement;
export default createElement;
