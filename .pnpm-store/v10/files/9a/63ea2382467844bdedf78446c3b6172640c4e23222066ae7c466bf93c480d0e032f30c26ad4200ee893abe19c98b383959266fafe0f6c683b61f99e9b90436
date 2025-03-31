const SVG = "http://www.w3.org/2000/svg"
const XLINK = "http://www.w3.org/1999/xlink"

const prefix = "ProseMirror-icon"

function hashPath(path: string) {
  let hash = 0
  for (let i = 0; i < path.length; i++)
    hash = (((hash << 5) - hash) + path.charCodeAt(i)) | 0
  return hash
}

export function getIcon(
  root: Document | ShadowRoot,
  icon: {path: string, width: number, height: number} | {text: string, css?: string} | {dom: Node}
): HTMLElement {
  let doc = (root.nodeType == 9 ? root as Document : root.ownerDocument) || document
  let node = doc.createElement("div")
  node.className = prefix
  if ((icon as any).path) {
    let {path, width, height} = icon as {path: string, width: number, height: number}
    let name = "pm-icon-" + hashPath(path).toString(16)
    if (!doc.getElementById(name)) buildSVG(root, name, icon as {path: string, width: number, height: number})
    let svg = node.appendChild(doc.createElementNS(SVG, "svg"))
    svg.style.width = (width / height) + "em"
    let use = svg.appendChild(doc.createElementNS(SVG, "use"))
    use.setAttributeNS(XLINK, "href", /([^#]*)/.exec(doc.location.toString())![1] + "#" + name)
  } else if ((icon as any).dom) {
    node.appendChild((icon as any).dom.cloneNode(true))
  } else {
    let {text, css} = icon as {text: string, css?: string}
    node.appendChild(doc.createElement("span")).textContent = text || ''
    if (css) (node.firstChild as HTMLElement).style.cssText = css
  }
  return node
}

function buildSVG(root: Document | ShadowRoot, name: string, data: {width: number, height: number, path: string}) {
  let [doc, top] = root.nodeType == 9 ? [root as Document, (root as Document).body] : [root.ownerDocument || document, root]
  let collection = doc.getElementById(prefix + "-collection") as Element
  if (!collection) {
    collection = doc.createElementNS(SVG, "svg")
    collection.id = prefix + "-collection"
    ;(collection as HTMLElement).style.display = "none"
    top.insertBefore(collection, top.firstChild)
  }
  let sym = doc.createElementNS(SVG, "symbol")
  sym.id = name
  sym.setAttribute("viewBox", "0 0 " + data.width + " " + data.height)
  let path = sym.appendChild(doc.createElementNS(SVG, "path"))
  path.setAttribute("d", data.path)
  collection.appendChild(sym)
}
