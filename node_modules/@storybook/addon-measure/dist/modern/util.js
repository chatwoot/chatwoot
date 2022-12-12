import global from 'global';
export const deepElementFromPoint = (x, y) => {
  const element = global.document.elementFromPoint(x, y);

  const crawlShadows = node => {
    if (node && node.shadowRoot) {
      const nestedElement = node.shadowRoot.elementFromPoint(x, y); // Nested node is same as the root one

      if (node.isEqualNode(nestedElement)) {
        return node;
      } // The nested node has shadow DOM too so continue crawling


      if (nestedElement.shadowRoot) {
        return crawlShadows(nestedElement);
      } // No more shadow DOM


      return nestedElement;
    }

    return node;
  };

  const shadowElement = crawlShadows(element);
  return shadowElement || element;
};