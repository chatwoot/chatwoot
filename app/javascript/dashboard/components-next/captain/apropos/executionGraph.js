export const GRAPH_LAYOUT = {
  width: 224,
  height: 72,
  column: 280,
  row: 104,
  padding: 16,
};

// Legacy traces lack span IDs. Group synchronous events using recorded depth
// and query boundaries, without inventing Scheme control-flow branches.
export function buildExecutionGraph(events, rootLabel) {
  const root = { index: -1, label: rootLabel, status: 'step', children: [] };
  const programs = new Map();
  const requests = new Map();
  const queries = new Map();
  const reasoning = new Map();
  events.forEach(event => {
    const node = { ...event, children: [] };
    const depth = event.depth || 0;
    [programs, requests, queries].forEach(map => {
      [...map.keys()].forEach(level => {
        if (level > depth) map.delete(level);
      });
    });
    let parent = programs.get(depth) || root;
    if (event.kind === 'program') {
      parent = programs.get(depth - 1) || root;
      programs.set(depth, node);
      requests.delete(depth);
      queries.delete(depth);
    } else if (event.kind === 'reason') {
      reasoning.set(event.reasonId, node);
    } else if (event.reasonId && reasoning.has(event.reasonId)) {
      parent = reasoning.get(event.reasonId);
      reasoning.delete(event.reasonId);
    } else if (event.kind === 'query_request') {
      requests.set(depth, node);
    } else if (event.kind === 'query') {
      parent = requests.get(depth) || parent;
      queries.set(depth, node);
    } else if (event.kind === 'error' || event.isQueryResult) {
      parent = queries.get(depth) || requests.get(depth) || parent;
      queries.delete(depth);
      if (event.isQueryResult) requests.delete(depth);
    }
    parent.children.push(node);
  });
  const nodes = [];
  const edges = [];
  let leaves = 0;
  let columns = 0;
  const { width, height, column, row, padding } = GRAPH_LAYOUT;
  const place = (node, level) => {
    node.x = padding + level * column;
    nodes.push(node);
    columns = Math.max(columns, level + 1);
    node.children.forEach(child => place(child, level + 1));
    if (node.children.length) {
      node.y = (node.children[0].y + node.children.at(-1).y) / 2;
    } else {
      node.y = padding + leaves * row;
      leaves += 1;
    }
    if (node.index === -1) node.y = padding;
    node.children.forEach(child => {
      const startX = node.x + width;
      const startY = node.y + height / 2;
      const endY = child.y + height / 2;
      const middleX = (startX + child.x) / 2;
      edges.push({
        id: child.index,
        status: child.status,
        path: `M ${startX} ${startY} H ${middleX} V ${endY} H ${child.x}`,
      });
    });
  };
  place(root, 0);
  return {
    nodes,
    edges,
    width: columns * column,
    height: leaves * row + padding * 2,
  };
}
