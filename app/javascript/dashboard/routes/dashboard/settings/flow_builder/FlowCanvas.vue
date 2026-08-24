<script>
export default {
  name: 'FlowCanvas',
  props: {
    nodes: { type: Array, required: true },
    edges: { type: Array, required: true },
    selectedNodeId: { type: String, default: null },
  },
  emits: ['node-moved', 'node-selected', 'connect', 'edge-delete'],
  data() {
    return {
      canvasOffset: { x: 0, y: 0 },
      isPanning: false,
      panStart: { x: 0, y: 0 },
      connecting: null, // { nodeId, startX, startY }
      connectingMouse: { x: 0, y: 0 },
    };
  },
  computed: {
    nodeStyle() {
      return (node) => ({
        transform: `translate(${node.position.x}px, ${node.position.y}px)`,
      });
    },
    nodeColor() {
      const colors = {
        trigger: '#1fe0b5',
        condition: '#ffc857',
        action: '#1ba5ff',
        ai_reply: '#8b5cf6',
        send_message: '#10b981',
      };
      return (type) => colors[type] || '#64748b';
    },
    nodeIcon() {
      const icons = {
        trigger: '⚡',
        condition: '🔀',
        action: '⚡',
        ai_reply: '🤖',
        send_message: '💬',
      };
      return (type) => icons[type] || '●';
    },
    edgePath() {
      return (edge) => {
        const source = this.nodes.find(n => n.id === edge.source);
        const target = this.nodes.find(n => n.id === edge.target);
        if (!source || !target) return '';
        const sx = source.position.x + 90;
        const sy = source.position.y + 50;
        const tx = target.position.x + 90;
        const ty = target.position.y + 50;
        const dx = Math.abs(tx - sx) * 0.4;
        return `M ${sx} ${sy} C ${sx + dx} ${sy}, ${tx - dx} ${ty}, ${tx} ${ty}`;
      };
    },
    connectingPath() {
      if (!this.connecting) return '';
      const sx = this.connecting.startX;
      const sy = this.connecting.startY;
      const tx = this.connectingMouse.x;
      const ty = this.connectingMouse.y;
      const dx = Math.abs(tx - sx) * 0.4;
      return `M ${sx} ${sy} C ${sx + dx} ${sy}, ${tx - dx} ${ty}, ${tx} ${ty}`;
    },
  },
  methods: {
    onCanvasMouseDown(e) {
      if (e.target === this.$refs.canvas || e.target.classList.contains('canvas-grid')) {
        this.isPanning = true;
        this.panStart = { x: e.clientX - this.canvasOffset.x, y: e.clientY - this.canvasOffset.y };
        this.$emit('node-selected', null);
      }
    },
    onCanvasMouseMove(e) {
      if (this.isPanning) {
        this.canvasOffset.x = e.clientX - this.panStart.x;
        this.canvasOffset.y = e.clientY - this.panStart.y;
      }
      if (this.connecting) {
        const rect = this.$refs.canvas.getBoundingClientRect();
        this.connectingMouse.x = e.clientX - rect.left - this.canvasOffset.x;
        this.connectingMouse.y = e.clientY - rect.top - this.canvasOffset.y;
      }
    },
    onCanvasMouseUp() {
      this.isPanning = false;
      this.connecting = null;
    },
    onNodeMouseDown(e, node) {
      e.stopPropagation();
      this.$emit('node-selected', node.id);

      // Start dragging
      const startX = e.clientX;
      const startY = e.clientY;
      const origPos = { ...node.position };

      const onMove = (ev) => {
        const dx = ev.clientX - startX;
        const dy = ev.clientY - startY;
        this.$emit('node-moved', {
          id: node.id,
          position: { x: origPos.x + dx, y: origPos.y + dy },
        });
      };
      const onUp = () => {
        document.removeEventListener('mousemove', onMove);
        document.removeEventListener('mouseup', onUp);
      };
      document.addEventListener('mousemove', onMove);
      document.addEventListener('mouseup', onUp);
    },
    onPortMouseDown(e, nodeId) {
      e.stopPropagation();
      const node = this.nodes.find(n => n.id === nodeId);
      if (!node) return;
      this.connecting = {
        nodeId,
        startX: node.position.x + 90,
        startY: node.position.y + 50,
      };
    },
    onPortMouseUp(e, targetId) {
      e.stopPropagation();
      if (this.connecting && this.connecting.nodeId !== targetId) {
        this.$emit('connect', { source: this.connecting.nodeId, target: targetId });
      }
      this.connecting = null;
    },
    onDeleteEdge(e, edge) {
      e.stopPropagation();
      this.$emit('edge-delete', { source: edge.source, target: edge.target });
    },
  },
};
</script>

<template>
  <div
    ref="canvas"
    class="flex-1 relative overflow-hidden bg-n-slate-2 cursor-grab"
    :class="{ 'cursor-grabbing': isPanning }"
    @mousedown="onCanvasMouseDown"
    @mousemove="onCanvasMouseMove"
    @mouseup="onCanvasMouseUp"
  >
    <!-- Grid background -->
    <div class="canvas-grid absolute inset-0"
      style="background-image: radial-gradient(circle, #cbd5e1 1px, transparent 1px); background-size: 20px 20px;"
    />

    <!-- Content layer -->
    <div
      class="absolute inset-0"
      :style="{ transform: `translate(${canvasOffset.x}px, ${canvasOffset.y}px)` }"
    >
      <!-- Edges -->
      <svg class="absolute inset-0 w-full h-full pointer-events-none" style="z-index: 1">
        <path
          v-for="(edge, i) in edges"
          :key="`edge-${i}`"
          :d="edgePath(edge)"
          fill="none"
          stroke="#94a3b8"
          stroke-width="2"
          class="pointer-events-auto cursor-pointer hover:stroke-n-ruby-11"
          @click="onDeleteEdge($event, edge)"
        />
        <!-- Live connecting line -->
        <path
          v-if="connecting"
          :d="connectingPath"
          fill="none"
          stroke="#1fe0b5"
          stroke-width="2"
          stroke-dasharray="6 4"
        />
      </svg>

      <!-- Nodes -->
      <div
        v-for="node in nodes"
        :key="node.id"
        class="absolute rounded-xl border-2 shadow-lg bg-n-background cursor-pointer select-none transition-shadow"
        :class="{
          'shadow-n-brand/30 border-n-brand': selectedNodeId === node.id,
          'border-n-slate-6 hover:border-n-slate-8': selectedNodeId !== node.id,
        }"
        :style="nodeStyle(node)"
        style="width: 180px; z-index: 2;"
        @mousedown="onNodeMouseDown($event, node)"
      >
        <!-- Header -->
        <div
          class="px-3 py-2 rounded-t-[10px] flex items-center gap-2"
          :style="{ backgroundColor: nodeColor(node.type) + '18' }"
        >
          <span class="text-sm">{{ nodeIcon(node.type) }}</span>
          <span class="text-xs font-medium text-n-slate-12">{{ node.type }}</span>
        </div>

        <!-- Body -->
        <div class="px-3 py-2 text-[11px] text-n-slate-11 min-h-[40px]">
          <template v-if="node.type === 'trigger'">
            Event: {{ node.data.event }}
          </template>
          <template v-else-if="node.type === 'condition'">
            {{ node.data.field }} {{ node.data.operator }} {{ node.data.value || '...' }}
          </template>
          <template v-else-if="node.type === 'action'">
            {{ node.data.action }}
          </template>
          <template v-else-if="node.type === 'ai_reply'">
            {{ (node.data.prompt || '').substring(0, 50) }}...
          </template>
          <template v-else-if="node.type === 'send_message'">
            {{ (node.data.content || '').substring(0, 50) }}...
          </template>
        </div>

        <!-- Connection ports -->
        <div
          class="absolute -top-2 left-1/2 -translate-x-1/2 w-4 h-4 rounded-full bg-n-slate-6 border-2 border-n-background cursor-crosshair hover:bg-n-brand hover:border-n-brand z-10"
          @mouseup="onPortMouseUp($event, node.id)"
        />
        <div
          class="absolute -bottom-2 left-1/2 -translate-x-1/2 w-4 h-4 rounded-full bg-n-slate-6 border-2 border-n-background cursor-crosshair hover:bg-n-brand hover:border-n-brand z-10"
          @mousedown="onPortMouseDown($event, node.id)"
        />
      </div>
    </div>
  </div>
</template>
