<script>
import { mapGetters } from 'vuex';

export default {
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  emits: ['select', 'keydown'],
  data() {
    return {
      selectedIndex: 0,
    };
  },
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
      this.selectedIndex = 0; // Reset selection on search
    },
    items() {
      // Reset selection if current index is out of bounds
      if (this.selectedIndex >= this.items.length) {
        this.selectedIndex = Math.max(0, this.items.length - 1);
      }
    },
  },
  mounted() {
    this.fetchCannedResponses();
    this.fetchTemplates();
    window.addEventListener('keydown', this.handleKeyDown);
  },
  beforeUnmount() {
    window.removeEventListener('keydown', this.handleKeyDown);
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
      this.$emit('select', item);

      // DIRECT WORKAROUND: Use global event bus
      if (item.type === 'template' && window.handleAppleTemplateSelect) {
        window.handleAppleTemplateSelect(item);
      }
    },
    handleKeyDown(event) {
      if (!this.hasItems) return;

      switch (event.key) {
        case 'ArrowDown':
          event.preventDefault();
          this.selectedIndex = Math.min(
            this.selectedIndex + 1,
            this.items.length - 1
          );
          this.scrollToSelected();
          break;
        case 'ArrowUp':
          event.preventDefault();
          this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
          this.scrollToSelected();
          break;
        case 'Enter':
          event.preventDefault();
          if (this.items[this.selectedIndex]) {
            this.handleSelect(this.items[this.selectedIndex]);
          }
          break;
        case 'Escape':
          this.$emit('keydown', event);
          break;
        default:
          // Allow other keys to pass through
          break;
      }
    },
    scrollToSelected() {
      this.$nextTick(() => {
        const selectedElement = this.$refs[`item-${this.selectedIndex}`]?.[0];
        if (selectedElement) {
          selectedElement.scrollIntoView({
            block: 'nearest',
            behavior: 'smooth',
          });
        }
      });
    },
  },
};
</script>

<template>
  <div v-if="hasItems" class="template-selector-list p-2">
    <div
      v-for="(item, index) in items"
      :key="item.key"
      :ref="`item-${index}`"
      class="template-item px-3 py-2 rounded-lg cursor-pointer transition-colors mb-1"
      :class="
        index === selectedIndex
          ? 'bg-n-blue-3 dark:bg-n-blue-3'
          : 'hover:bg-n-alpha-2 dark:hover:bg-n-alpha-3'
      "
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
          <span v-if="item.type === 'template'">{{
            $t('TEMPLATES.SELECTOR.TEMPLATE_ICON')
          }}</span>
          <span v-else>{{ $t('TEMPLATES.SELECTOR.CANNED_ICON') }}</span>
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
      {{ $t('TEMPLATES.SELECTOR.NO_MATCH', { searchKey }) }}
    </div>
    <div v-else class="italic">
      {{ $t('TEMPLATES.SELECTOR.NO_AVAILABLE') }}
    </div>
  </div>
</template>

<style scoped>
.template-selector-list {
  max-height: 400px;
  overflow-y: auto;
}
</style>
