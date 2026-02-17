<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  node: {
    type: Object,
    required: true,
  },
  depth: {
    type: Number,
    default: 0,
  },
  expandedFolders: {
    type: Set,
    required: true,
  },
  selectedItem: {
    type: Object,
    default: null,
  },
  getFileIcon: {
    type: Function,
    required: true,
  },
  formatFileSize: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['toggle-expand', 'select-folder', 'select-file']);

const { t } = useI18n();

const isExpanded = computed(() => props.expandedFolders.has(props.node.path));
const paddingLeft = computed(() => `${(props.depth + 1) * 1.5}rem`);

const isFolderSelected = computed(() => {
  return props.selectedItem?.type === 'folder' && props.selectedItem?.data?.id === props.node.id;
});

const isFileSelected = (fileId) => {
  return props.selectedItem?.type === 'file' && props.selectedItem?.data?.id === fileId;
};

const hasContent = computed(() => {
  return (props.node.children?.length > 0) || (props.node.files?.length > 0);
});

const toggleExpand = () => {
  emit('toggle-expand', props.node.path);
};

const selectFolder = () => {
  emit('select-folder', props.node);
};

const selectFile = (file) => {
  emit('select-file', file);
};
</script>

<template>
  <div class="tree-node-wrapper">
    <!-- Folder row -->
    <div
      class="flex items-center gap-2 px-4 py-2 cursor-pointer transition-colors border-b border-n-weak/50 whitespace-nowrap min-w-max"
      :class="isFolderSelected ? 'bg-n-blue-3 hover:bg-n-blue-4' : 'hover:bg-n-alpha-2'"
      :style="{ paddingLeft }"
    >
      <button
        v-if="hasContent"
        class="p-0.5 hover:bg-n-alpha-3 rounded shrink-0"
        @click.stop="toggleExpand"
      >
        <i
          :class="isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
          class="w-4 h-4 text-n-slate-10"
        />
      </button>
      <i v-else class="w-5 h-5 shrink-0" />

      <div class="flex items-center gap-2 flex-1" @click="selectFolder">
        <i class="i-lucide-folder w-4 h-4 text-n-amber-11 shrink-0" />
        <span class="text-sm text-n-slate-12">{{ node.name }}</span>
        <span v-if="hasContent" class="text-xs text-n-slate-10 ml-2 shrink-0">
          ({{ (node.children?.length || 0) + (node.files?.length || 0) }})
        </span>
      </div>
    </div>

    <!-- Expanded content -->
    <template v-if="isExpanded">
      <!-- Nested folders (recursive) -->
      <TreeNode
        v-for="child in node.children"
        :key="child.path"
        :node="child"
        :depth="depth + 1"
        :expanded-folders="expandedFolders"
        :selected-item="selectedItem"
        :get-file-icon="getFileIcon"
        :format-file-size="formatFileSize"
        @toggle-expand="$emit('toggle-expand', $event)"
        @select-folder="$emit('select-folder', $event)"
        @select-file="$emit('select-file', $event)"
      />

      <!-- Files in this folder -->
      <div
        v-for="file in node.files"
        :key="file.id"
        class="flex items-center gap-2 px-4 py-2 cursor-pointer transition-colors border-b border-n-weak/50 whitespace-nowrap min-w-max"
        :class="isFileSelected(file.id) ? 'bg-n-blue-3 hover:bg-n-blue-4' : 'hover:bg-n-alpha-2'"
        :style="{ paddingLeft: `${(depth + 2) * 1.5}rem` }"
        @click="selectFile(file)"
      >
        <i class="w-5 h-5 shrink-0" />
        <i :class="[getFileIcon(file.content_type), 'w-4 h-4 text-n-slate-11 shrink-0']" />
        <span class="text-sm text-n-slate-12">{{ file.name }}</span>
        <span
          v-if="!file.is_visible"
          class="text-xs text-n-amber-11 bg-n-amber-3 px-1 py-0.5 rounded ml-1 shrink-0"
        >
          {{ t('KNOWLEDGE_BASE.RESOURCES.HIDDEN') }}
        </span>
        <span
          v-if="file.product_catalogs?.length"
          class="text-xs text-n-blue-11 bg-n-blue-3 px-1 py-0.5 rounded ml-1 shrink-0"
        >
          {{ file.product_catalogs.length }} {{ file.product_catalogs.length === 1 ? 'product' : 'products' }}
        </span>
        <span class="text-xs text-n-slate-10 ml-2 shrink-0">
          {{ formatFileSize(file.file_size) }}
        </span>
      </div>
    </template>
  </div>
</template>
