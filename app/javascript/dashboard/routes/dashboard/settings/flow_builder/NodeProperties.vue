<script>
export default {
  name: 'NodeProperties',
  props: {
    node: { type: Object, required: true },
  },
  emits: ['update', 'delete'],
  computed: {
    fieldOptions() {
      return [
        { value: 'inbox_id', label: 'Inbox ID' },
        { value: 'status', label: 'Status' },
        { value: 'assignee_id', label: 'Assignee ID' },
        { value: 'contact_name', label: 'Contact Name' },
        { value: 'contact_email', label: 'Contact Email' },
        { value: 'message_content', label: 'Message Content' },
      ];
    },
    operatorOptions() {
      return [
        { value: 'equals', label: 'Equals' },
        { value: 'not_equals', label: 'Not Equals' },
        { value: 'contains', label: 'Contains' },
        { value: 'greater_than', label: 'Greater Than' },
        { value: 'less_than', label: 'Less Than' },
      ];
    },
    actionOptions() {
      return [
        { value: 'assign_agent', label: 'Assign Agent' },
        { value: 'set_status', label: 'Set Status' },
        { value: 'add_label', label: 'Add Label' },
        { value: 'remove_label', label: 'Remove Label' },
        { value: 'send_notification', label: 'Send Notification' },
      ];
    },
    triggerEventOptions() {
      return [
        { value: 'conversation_created', label: 'Conversation Created' },
        { value: 'message_created', label: 'Message Created' },
        { value: 'conversation_status_changed', label: 'Status Changed' },
        { value: 'conversation_assigned', label: 'Conversation Assigned' },
      ];
    },
    statusOptions() {
      return [
        { value: 'open', label: 'Open' },
        { value: 'resolved', label: 'Resolved' },
        { value: 'pending', label: 'Pending' },
        { value: 'snoozed', label: 'Snoozed' },
      ];
    },
  },
};
</script>

<template>
  <div class="w-72 border-l border-n-slate-6 bg-n-surface-1 p-4 overflow-y-auto">
    <div class="flex items-center justify-between mb-4">
      <h4 class="text-sm font-medium text-n-slate-12">Properties</h4>
      <button
        class="text-xs text-n-ruby-11 hover:text-n-ruby-12"
        @click="$emit('delete')"
      >
        Delete Node
      </button>
    </div>

    <div class="space-y-4">
      <!-- Node ID (read-only) -->
      <div>
        <label class="block text-[11px] text-n-slate-10 mb-1">Node ID</label>
        <div class="text-xs text-n-slate-11 font-mono bg-n-slate-3 px-2 py-1 rounded">
          {{ node.id }}
        </div>
      </div>

      <!-- Trigger -->
      <template v-if="node.type === 'trigger'">
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">Trigger Event</label>
          <select
            :value="node.data.event"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            @change="$emit('update', { event: $event.target.value })"
          >
            <option v-for="opt in triggerEventOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>
      </template>

      <!-- Condition -->
      <template v-if="node.type === 'condition'">
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">Field</label>
          <select
            :value="node.data.field"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            @change="$emit('update', { field: $event.target.value })"
          >
            <option v-for="opt in fieldOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">Operator</label>
          <select
            :value="node.data.operator"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            @change="$emit('update', { operator: $event.target.value })"
          >
            <option v-for="opt in operatorOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">Value</label>
          <input
            :value="node.data.value"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            placeholder="Compare value..."
            @input="$emit('update', { value: $event.target.value })"
          />
        </div>
      </template>

      <!-- Action -->
      <template v-if="node.type === 'action'">
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">Action Type</label>
          <select
            :value="node.data.action"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            @change="$emit('update', { action: $event.target.value })"
          >
            <option v-for="opt in actionOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>
        <div v-if="node.data.action === 'assign_agent'">
          <label class="block text-[11px] text-n-slate-10 mb-1">Agent ID</label>
          <input
            :value="node.data.agent_id"
            type="number"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            placeholder="Agent ID..."
            @input="$emit('update', { agent_id: parseInt($event.target.value) || '' })"
          />
        </div>
        <div v-if="node.data.action === 'set_status'">
          <label class="block text-[11px] text-n-slate-10 mb-1">Status</label>
          <select
            :value="node.data.status"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            @change="$emit('update', { status: $event.target.value })"
          >
            <option v-for="opt in statusOptions" :key="opt.value" :value="opt.value">
              {{ opt.label }}
            </option>
          </select>
        </div>
        <div v-if="node.data.action === 'add_label' || node.data.action === 'remove_label'">
          <label class="block text-[11px] text-n-slate-10 mb-1">Label</label>
          <input
            :value="node.data.label"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12"
            placeholder="Label name..."
            @input="$emit('update', { label: $event.target.value })"
          />
        </div>
      </template>

      <!-- AI Reply -->
      <template v-if="node.type === 'ai_reply'">
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">AI Prompt</label>
          <textarea
            :value="node.data.prompt"
            rows="4"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12 resize-none"
            placeholder="Instructions for the AI..."
            @input="$emit('update', { prompt: $event.target.value })"
          />
        </div>
      </template>

      <!-- Send Message -->
      <template v-if="node.type === 'send_message'">
        <div>
          <label class="block text-[11px] text-n-slate-10 mb-1">Message Content</label>
          <textarea
            :value="node.data.content"
            rows="4"
            class="w-full px-2 py-1.5 text-xs border rounded border-n-slate-6 bg-n-background text-n-slate-12 resize-none"
            placeholder="Message to send..."
            @input="$emit('update', { content: $event.target.value })"
          />
        </div>
      </template>
    </div>
  </div>
</template>
