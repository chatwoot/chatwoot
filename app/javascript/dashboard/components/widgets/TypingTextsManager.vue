<script>
import { useAlert } from 'dashboard/composables';

export default {
  name: 'TypingTextsManager',
  props: {
    value: {
      type: Array,
      default: () => [],
    },
    modelValue: {
      type: Array,
      default: () => [],
    },
    label: {
      type: String,
      default: 'Typing Texts',
    },
    placeholder: {
      type: String,
      default: 'Enter typing text...',
    },
    maxTexts: {
      type: Number,
      default: 20,
    },
    maxLength: {
      type: Number,
      default: 100,
    },
  },
  emits: ['input', 'update:modelValue'],
  data() {
    return {
      texts: [...(this.modelValue || this.value)],
      newText: '',
      draggedIndex: null,
    };
  },
  computed: {
    canAddMore() {
      return this.texts.length < this.maxTexts;
    },
    isNewTextValid() {
      return this.newText.trim().length > 0 && this.newText.length <= this.maxLength;
    },
  },
  watch: {
    value: {
      handler(newValue) {
        this.texts = [...newValue];
      },
      deep: true,
    },
    modelValue: {
      handler(newValue) {
        this.texts = [...(newValue || [])];
      },
      deep: true,
    },
    texts: {
      handler() {
        this.$emit('input', this.texts);
        this.$emit('update:modelValue', this.texts);
      },
      deep: true,
    },
  },
  methods: {
    addText() {
      if (!this.isNewTextValid || !this.canAddMore) return;
      
      const trimmedText = this.newText.trim();
      if (this.texts.includes(trimmedText)) {
        useAlert('Text already exists');
        return;
      }
      
      this.texts.push(trimmedText);
      this.newText = '';
    },
    removeText(index) {
      this.texts.splice(index, 1);
    },
    editText(index, newValue) {
      if (newValue.trim().length === 0) {
        this.removeText(index);
        return;
      }
      
      if (newValue.length > this.maxLength) {
        useAlert(`Text cannot be longer than ${this.maxLength} characters`);
        return;
      }
      
      this.texts[index] = newValue.trim();
    },
    moveUp(index) {
      if (index === 0) return;
      const temp = this.texts[index];
      this.texts[index] = this.texts[index - 1];
      this.texts[index - 1] = temp;
    },
    moveDown(index) {
      if (index === this.texts.length - 1) return;
      const temp = this.texts[index];
      this.texts[index] = this.texts[index + 1];
      this.texts[index + 1] = temp;
    },
    onDragStart(event, index) {
      this.draggedIndex = index;
      event.dataTransfer.effectAllowed = 'move';
    },
    onDragOver(event) {
      event.preventDefault();
      event.dataTransfer.dropEffect = 'move';
    },
    onDrop(event, targetIndex) {
      event.preventDefault();
      if (this.draggedIndex === null || this.draggedIndex === targetIndex) return;
      
      const draggedText = this.texts[this.draggedIndex];
      this.texts.splice(this.draggedIndex, 1);
      this.texts.splice(targetIndex, 0, draggedText);
      this.draggedIndex = null;
    },
    resetToDefault() {
      this.texts = [
        'Xin chào! Tôi có thể giúp gì cho bạn?',
        'Hỗ trợ 24/7 - Luôn sẵn sàng!',
        'Chat ngay để được tư vấn miễn phí',
        'Mooly.vn - Giải pháp AI thông minh',
        'Bạn cần hỗ trợ gì không?',
        'Nhấn để bắt đầu trò chuyện',
        'AI Assistant đang chờ bạn...',
        'Tư vấn nhanh - Phản hồi tức thì'
      ];
    },
  },
};
</script>

<template>
  <div class="typing-texts-manager">
    <label class="block text-sm font-medium text-slate-800 dark:text-slate-200 mb-2">
      {{ label }}
      <span class="text-slate-600 dark:text-slate-400 text-xs ml-1">
        ({{ texts.length }}/{{ maxTexts }})
      </span>
    </label>
    
    <!-- Add new text -->
    <div class="flex gap-2 mb-4">
      <input
        v-model="newText"
        type="text"
        :placeholder="placeholder"
        :maxlength="maxLength"
        class="flex-1 px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100"
        @keydown.enter="addText"
      />
      <button
        type="button"
        :disabled="!isNewTextValid || !canAddMore"
        class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        @click="addText"
      >
        Add
      </button>
    </div>
    
    <!-- Character count for new text -->
    <div v-if="newText" class="text-xs text-slate-600 dark:text-slate-400 mb-2">
      {{ newText.length }}/{{ maxLength }} characters
    </div>
    
    <!-- Existing texts list -->
    <div v-if="texts.length > 0" class="space-y-2 mb-4">
      <div
        v-for="(text, index) in texts"
        :key="index"
        class="flex items-center gap-2 p-3 bg-slate-50 dark:bg-slate-700 rounded-md border border-slate-200 dark:border-slate-600"
        draggable="true"
        @dragstart="onDragStart($event, index)"
        @dragover="onDragOver"
        @drop="onDrop($event, index)"
      >
        <!-- Drag handle -->
        <div class="cursor-move text-slate-500 dark:text-slate-400">
          <span class="text-base">⋮⋮</span>
        </div>
        
        <!-- Text input -->
        <input
          :value="text"
          type="text"
          :maxlength="maxLength"
          class="flex-1 px-2 py-1 bg-transparent border-none focus:outline-none focus:ring-1 focus:ring-blue-500 rounded text-slate-900 dark:text-slate-100"
          @input="editText(index, $event.target.value)"
          @blur="editText(index, $event.target.value)"
        />
        
        <!-- Character count -->
        <span class="text-xs text-slate-500 dark:text-slate-400 min-w-[3rem]">
          {{ text.length }}/{{ maxLength }}
        </span>
        
        <!-- Move buttons -->
        <div class="flex gap-1">
          <button
            type="button"
            :disabled="index === 0"
            class="p-1 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 disabled:opacity-50"
            @click="moveUp(index)"
          >
            <span class="text-sm">↑</span>
          </button>
          <button
            type="button"
            :disabled="index === texts.length - 1"
            class="p-1 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 disabled:opacity-50"
            @click="moveDown(index)"
          >
            <span class="text-sm">↓</span>
          </button>
        </div>
        
        <!-- Remove button -->
        <button
          type="button"
          class="p-1 text-red-500 hover:text-red-700"
          @click="removeText(index)"
        >
          <span class="text-sm">×</span>
        </button>
      </div>
    </div>
    
    <!-- Actions -->
    <div class="flex gap-2">
      <button
        type="button"
        class="px-3 py-1 text-sm bg-slate-200 dark:bg-slate-600 text-slate-800 dark:text-slate-200 rounded hover:bg-slate-300 dark:hover:bg-slate-500"
        @click="resetToDefault"
      >
        Reset to Default
      </button>
      <div class="text-xs text-slate-500 dark:text-slate-400 flex items-center">
        Drag to reorder • Click text to edit • Max {{ maxLength }} chars each
      </div>
    </div>
  </div>
</template>

<style scoped>
.typing-texts-manager input:focus {
  outline: none;
}
</style>
