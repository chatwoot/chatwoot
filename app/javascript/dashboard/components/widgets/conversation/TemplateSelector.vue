<script>
import { mapGetters } from 'vuex';
import MentionBox from '../mentions/MentionBox.vue';

export default {
  components: { MentionBox },
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  emits: ['select'],
  computed: {
    ...mapGetters({
      cannedMessages: 'getCannedResponses',
      currentChat: 'getSelectedChat',
    }),
    inboxId() {
      return this.currentChat?.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    channelType() {
      // Get channel type from inbox
      const inboxChannelType = this.inbox?.channel_type || '';
      // Normalize to snake_case for API compatibility
      return inboxChannelType
        .replace(/^Channel::/, '')
        .replace(/([A-Z])/g, '_$1')
        .toLowerCase()
        .replace(/^_/, '');
    },
    templates() {
      // This will be populated from Vuex store
      return this.$store.getters['messageTemplates/getTemplates'] || [];
    },
    filteredTemplates() {
      if (!this.searchKey) return this.templates;

      const searchLower = this.searchKey.toLowerCase();
      return this.templates.filter(
        template =>
          template.name.toLowerCase().includes(searchLower) ||
          template.description?.toLowerCase().includes(searchLower) ||
          template.tags?.some(tag => tag.toLowerCase().includes(searchLower))
      );
    },
    cannedItems() {
      return this.cannedMessages.map(cannedMessage => ({
        label: `${cannedMessage.short_code}`,
        key: `canned_${cannedMessage.id}`,
        description: cannedMessage.content,
        type: 'canned',
        content: cannedMessage.content,
      }));
    },
    templateItems() {
      return this.filteredTemplates
        .filter(
          template =>
            (
              template.supportedChannels ||
              template.supported_channels ||
              []
            ).includes(this.channelType) && template.status === 'active'
        )
        .map(template => ({
          label: template.name,
          key: `template_${template.id}`,
          description: template.description || 'Template',
          type: 'template',
          template: template,
        }));
    },
    items() {
      // Combine canned responses and templates for all channels
      // Templates are filtered by channel compatibility already
      return [...this.cannedItems, ...this.templateItems];
    },
    hasItems() {
      return this.items.length > 0;
    },
  },
  watch: {
    searchKey() {
      this.fetchCannedResponses();
      this.fetchTemplates();
    },
  },
  mounted() {
    this.fetchCannedResponses();
    this.fetchTemplates();
  },
  methods: {
    fetchCannedResponses() {
      this.$store.dispatch('getCannedResponse', { searchKey: this.searchKey });
    },
    fetchTemplates() {
      this.$store.dispatch('messageTemplates/get', {
        search: this.searchKey,
        channel: this.channelType,
      });
    },
    handleSelect(item = {}) {
      console.log('[TemplateSelector] Item clicked:', item);
      console.log('[TemplateSelector] About to emit select event');
      this.$emit('select', item);
      console.log('[TemplateSelector] Select event emitted');

      // DIRECT WORKAROUND: Use global event bus
      if (item.type === 'template' && window.handleAppleTemplateSelect) {
        console.log('[TemplateSelector] Calling global handleAppleTemplateSelect');
        window.handleAppleTemplateSelect(item);
      }
    },
  },
};
</script>

<template>
  <div v-if="hasItems" class="template-selector-list p-2">
    <div
      v-for="item in items"
      :key="item.key"
      class="template-item px-3 py-2 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-3 rounded-lg cursor-pointer transition-colors mb-1"
      @click="handleSelect(item)"
    >
      <div class="flex items-start gap-2">
        <div
          class="flex-shrink-0 w-8 h-8 rounded-lg flex items-center justify-center text-lg"
          :class="
            item.type === 'template'
              ? 'bg-n-woot-1 dark:bg-n-woot-2 text-n-woot-9'
              : 'bg-n-blue-1 dark:bg-n-blue-2 text-n-blue-9'
          "
        >
          <span v-if="item.type === 'template'">📋</span>
          <span v-else>📝</span>
        </div>
        <div class="flex-1 min-w-0">
          <div
            class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11 truncate"
          >
            {{ item.label }}
          </div>
          <div
            class="text-xs text-n-slate-11 dark:text-n-slate-10 truncate mt-0.5"
          >
            {{ item.description }}
          </div>
          <div v-if="item.template" class="flex gap-1 mt-1">
            <span
              v-for="tag in (item.template.tags || []).slice(0, 3)"
              :key="tag"
              class="text-xs px-1.5 py-0.5 bg-n-alpha-2 dark:bg-n-alpha-3 text-n-slate-11 dark:text-n-slate-10 rounded"
            >
              {{ tag }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div
    v-else
    class="p-4 text-center text-sm text-n-slate-10 dark:text-n-slate-9"
  >
    <div v-if="searchKey" class="italic">
      No templates found matching "{{ searchKey }}"
    </div>
    <div v-else class="italic">No templates available for this channel</div>
  </div>
</template>

<style scoped>
.template-selector-list {
  max-height: 400px;
  overflow-y: auto;
}
</style>
