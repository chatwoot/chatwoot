function renderNode(tagName, content) {
    const element = content.xmlns
        ? document.createElementNS(content.xmlns, tagName)
        : document.createElement(tagName);
    for (const [key, value] of Object.entries(content)) {
        if (key === 'children') {
            for (const [key, value] of Object.entries(content)) {
                if (typeof value === 'string') {
                    element.appendChild(document.createTextNode(value));
                }
                else {
                    element.appendChild(renderNode(key, value));
                }
            }
        }
        else if (key === 'style') {
            Object.assign(element.style, value);
        }
        else if (key === 'textContent') {
            element.textContent = value;
        }
        else {
            element.setAttribute(key, value.toString());
        }
    }
    return element;
}
export function createElement(tagName, content, container) {
    const el = renderNode(tagName, content || {});
    container === null || container === void 0 ? void 0 : container.appendChild(el);
    return el;
}
export default createElement;
