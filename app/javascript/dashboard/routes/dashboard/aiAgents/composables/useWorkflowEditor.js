import { ref, computed, watch } from 'vue';
import { useVueFlow } from '@vue-flow/core';
import dagre from '@dagrejs/dagre';
import { NODE_TYPES_META } from '../components/workflow/nodeTypes';

const NANOID_CHARS = 'abcdefghijklmnopqrstuvwxyz0123456789';

function nanoid(size = 8) {
  let id = '';
  for (let i = 0; i < size; i += 1) {
    id += NANOID_CHARS[Math.floor(Math.random() * NANOID_CHARS.length)];
  }
  return id;
}

export function useWorkflowEditor() {
  const {
    nodes,
    edges,
    addNodes,
    addEdges,
    removeNodes,
    removeEdges,
    onConnect,
    onNodesChange,
    onEdgesChange,
    fitView,
    getNodes,
    getEdges,
    setNodes,
    setEdges,
    project,
  } = useVueFlow({
    defaultEdgeOptions: {
      type: 'smoothstep',
      animated: true,
    },
  });

  const isDirty = ref(false);
  const selectedNodeId = ref(null);
  const canvasState = ref({ zoom: 1, x: 0, y: 0 });

  // Track changes
  watch(
    [nodes, edges],
    () => {
      isDirty.value = true;
    },
    { deep: true }
  );

  const selectedNode = computed(() => {
    if (!selectedNodeId.value) return null;
    return nodes.value.find(n => n.id === selectedNodeId.value) || null;
  });

  function generateNodeId() {
    return `node_${nanoid(8)}`;
  }

  function generateEdgeId() {
    return `edge_${nanoid(8)}`;
  }

  // Add a new node of the given type at position
  function addNode(type, position = { x: 250, y: 250 }) {
    const meta = NODE_TYPES_META[type];
    if (!meta) return null;

    const id = generateNodeId();
    const newNode = {
      id,
      type,
      position: { ...position },
      data: {
        label: meta.defaultLabel,
        ...structuredClone(meta.defaultData || {}),
      },
    };

    addNodes([newNode]);
    return id;
  }

  // Remove a node (and its connected edges)
  function removeNode(nodeId) {
    if (selectedNodeId.value === nodeId) {
      selectedNodeId.value = null;
    }
    removeNodes([nodeId]);
  }

  // Validate edge connection: check handle type compatibility
  function isValidConnection(connection) {
    const sourceNode = nodes.value.find(n => n.id === connection.source);
    const targetNode = nodes.value.find(n => n.id === connection.target);
    if (!sourceNode || !targetNode) return false;

    const sourceMeta = NODE_TYPES_META[sourceNode.type];
    const targetMeta = NODE_TYPES_META[targetNode.type];
    if (!sourceMeta || !targetMeta) return false;

    const sourceHandle = sourceMeta.outputs?.find(
      h => h.id === connection.sourceHandle
    );
    const targetHandle = targetMeta.inputs?.find(
      h => h.id === connection.targetHandle
    );
    if (!sourceHandle || !targetHandle) return false;

    // flow ↔ flow, data ↔ data, messages ↔ messages
    return sourceHandle.type === targetHandle.type;
  }

  // Handle connection events
  onConnect(params => {
    if (!isValidConnection(params)) return;

    addEdges([
      {
        id: generateEdgeId(),
        source: params.source,
        sourceHandle: params.sourceHandle,
        target: params.target,
        targetHandle: params.targetHandle,
        animated: true,
        type: 'smoothstep',
      },
    ]);
  });

  // Auto-layout using dagre
  function autoLayout(direction = 'LR') {
    const g = new dagre.graphlib.Graph();
    g.setDefaultEdgeLabel(() => ({}));
    g.setGraph({
      rankdir: direction,
      nodesep: 80,
      ranksep: 120,
      marginx: 50,
      marginy: 50,
    });

    const currentNodes = getNodes.value;
    const currentEdges = getEdges.value;

    currentNodes.forEach(node => {
      g.setNode(node.id, { width: 240, height: 100 });
    });

    currentEdges.forEach(edge => {
      g.setEdge(edge.source, edge.target);
    });

    dagre.layout(g);

    const layoutedNodes = currentNodes.map(node => {
      const nodeWithPosition = g.node(node.id);
      return {
        ...node,
        position: {
          x: nodeWithPosition.x - 120,
          y: nodeWithPosition.y - 50,
        },
      };
    });

    setNodes(layoutedNodes);

    setTimeout(() => {
      fitView({ padding: 0.2 });
    }, 50);
  }

  // Load workflow JSON into the canvas
  function loadWorkflow(workflowJson) {
    if (!workflowJson || !workflowJson.nodes) {
      setNodes([]);
      setEdges([]);
      isDirty.value = false;
      return;
    }

    const loadedNodes = Object.entries(workflowJson.nodes).map(
      ([id, nodeData]) => ({
        id,
        type: nodeData.type,
        position: nodeData.position || { x: 0, y: 0 },
        data: nodeData.data || {},
      })
    );

    const loadedEdges = (workflowJson.edges || []).map(edge => ({
      id: edge.id,
      source: edge.source,
      sourceHandle: edge.source_handle,
      target: edge.target,
      targetHandle: edge.target_handle,
      animated: true,
      type: 'smoothstep',
      data: edge.data_mapping ? { dataMapping: edge.data_mapping } : undefined,
    }));

    setNodes(loadedNodes);
    setEdges(loadedEdges);

    if (workflowJson.meta?.canvas) {
      canvasState.value = workflowJson.meta.canvas;
    }

    setTimeout(() => {
      isDirty.value = false;
    }, 100);
  }

  // Serialize canvas state back to workflow JSON
  function toWorkflowJson(meta = {}) {
    const currentNodes = getNodes.value;
    const currentEdges = getEdges.value;

    const nodesObj = {};
    currentNodes.forEach(node => {
      nodesObj[node.id] = {
        type: node.type,
        position: {
          x: Math.round(node.position.x),
          y: Math.round(node.position.y),
        },
        data: { ...node.data },
      };
    });

    const edgesArr = currentEdges.map(edge => {
      const edgeObj = {
        id: edge.id,
        source: edge.source,
        source_handle: edge.sourceHandle,
        target: edge.target,
        target_handle: edge.targetHandle,
      };
      if (edge.data?.dataMapping) {
        edgeObj.data_mapping = edge.data.dataMapping;
      }
      return edgeObj;
    });

    return {
      version: 2,
      meta: {
        name: meta.name || 'Untitled Workflow',
        description: meta.description || '',
        canvas: { ...canvasState.value },
      },
      nodes: nodesObj,
      edges: edgesArr,
      variables: meta.variables || {},
    };
  }

  // Select a node for config editing
  function selectNode(nodeId) {
    selectedNodeId.value = nodeId;
  }

  function deselectNode() {
    selectedNodeId.value = null;
  }

  // Update data on the currently selected node
  function updateNodeData(nodeId, newData) {
    const node = nodes.value.find(n => n.id === nodeId);
    if (node) {
      node.data = { ...node.data, ...newData };
    }
  }

  return {
    // Vue Flow state
    nodes,
    edges,
    onNodesChange,
    onEdgesChange,
    fitView,
    project,

    // Custom state
    isDirty,
    selectedNodeId,
    selectedNode,
    canvasState,

    // Actions
    addNode,
    removeNode,
    addNodes,
    addEdges,
    removeEdges,
    selectNode,
    deselectNode,
    updateNodeData,
    autoLayout,
    loadWorkflow,
    toWorkflowJson,
    isValidConnection,
  };
}
