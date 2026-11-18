<script setup>
import {
  computed,
  onBeforeUnmount,
  onMounted,
  ref,
  shallowRef,
  useTemplateRef,
} from 'vue';
import { useI18n } from 'vue-i18n';
import {
  drawOperation,
  editedFileName,
  isMeaningfulOperation,
  renderOperations,
  toCanvasPoint,
} from 'shared/helpers/imageEditor';

const props = defineProps({
  file: { type: File, required: true },
  // The widget passes classes for the inbox color and its dark mode, which the teleported
  // editor does not inherit. The dashboard keeps the defaults: its dark class is on the body.
  confirmClass: { type: String, default: 'bg-n-brand text-white' },
  isDark: { type: Boolean, default: false },
  // "Send" when the image goes out on confirm; "Done" when it goes back to a composer.
  confirmLabel: { type: String, default: '' },
  // Upload limit in MB. An edit above it keeps the editor open, so the user can crop more.
  maxSizeMb: { type: Number, default: 0 },
});

const emit = defineEmits(['save', 'cancel']);

const { t } = useI18n();

const tools = computed(() => [
  {
    id: 'arrow',
    icon: 'i-lucide-move-up-right',
    label: t('IMAGE_EDITOR.TOOLS.ARROW'),
  },
  {
    id: 'rect',
    icon: 'i-lucide-square',
    label: t('IMAGE_EDITOR.TOOLS.RECTANGLE'),
  },
  {
    id: 'ellipse',
    icon: 'i-lucide-circle',
    label: t('IMAGE_EDITOR.TOOLS.ELLIPSE'),
  },
  {
    id: 'blur',
    icon: 'i-lucide-scan-eye',
    label: t('IMAGE_EDITOR.TOOLS.BLUR'),
  },
  { id: 'crop', icon: 'i-lucide-crop', label: t('IMAGE_EDITOR.TOOLS.CROP') },
]);

const dialogRef = useTemplateRef('dialogRef');
const canvasRef = useTemplateRef('canvasRef');
const image = shallowRef(null);
const operations = ref([]);
const redoStack = ref([]);
const activeTool = ref('arrow');
const isSaving = ref(false);
const exportError = ref('');

const canUndo = computed(() => operations.value.length > 0);
const canRedo = computed(() => redoStack.value.length > 0);

// The committed result is cached, so a drag only repaints it plus the shape in progress.
let rendered = null;
let draft = null;
let isUnmounted = false;
let previousFocus = null;

const paint = () => {
  const canvas = canvasRef.value;
  if (canvas.width !== rendered.width) canvas.width = rendered.width;
  if (canvas.height !== rendered.height) canvas.height = rendered.height;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(rendered, 0, 0);
  if (draft) drawOperation(canvas, draft);
};

const commit = () => {
  rendered = renderOperations(image.value, operations.value);
  paint();
};

const onPointerDown = event => {
  if (!event.isPrimary || !rendered) return;
  canvasRef.value.setPointerCapture(event.pointerId);
  const point = toCanvasPoint(event, canvasRef.value);
  draft = { type: activeTool.value, start: point, end: point };
};

const onPointerMove = event => {
  if (!draft || !event.isPrimary) return;
  draft.end = toCanvasPoint(event, canvasRef.value);
  paint();
};

const onPointerUp = event => {
  if (!draft || !event.isPrimary) return;
  const operation = draft;
  draft = null;
  if (!isMeaningfulOperation(operation)) {
    paint();
    return;
  }
  operations.value.push(operation);
  redoStack.value = [];
  commit();
};

const onPointerCancel = () => {
  draft = null;
  if (rendered) paint();
};

const undo = () => {
  if (!canUndo.value) return;
  redoStack.value.push(operations.value.pop());
  commit();
};

const redo = () => {
  if (!canRedo.value) return;
  operations.value.push(redoStack.value.pop());
  commit();
};

const save = () => {
  if (!operations.value.length) {
    emit('save', props.file);
    return;
  }
  isSaving.value = true;
  rendered.toBlob(blob => {
    // The browser returns null when it cannot encode the canvas, such as when memory runs out.
    if (!blob) {
      isSaving.value = false;
      exportError.value = t('IMAGE_EDITOR.EXPORT_ERROR');
      return;
    }
    if (props.maxSizeMb && blob.size > props.maxSizeMb * 1024 * 1024) {
      isSaving.value = false;
      exportError.value = t('IMAGE_EDITOR.TOO_LARGE', {
        size: props.maxSizeMb,
      });
      return;
    }
    emit(
      'save',
      new File([blob], editedFileName(props.file.name), { type: 'image/png' })
    );
  }, 'image/png');
};

const onKeydown = event => {
  if (event.key === 'Escape') {
    emit('cancel');
    return;
  }
  if (!(event.ctrlKey || event.metaKey) || event.key.toLowerCase() !== 'z') {
    return;
  }
  event.preventDefault();
  if (event.shiftKey) redo();
  else undo();
};

// The chat input takes the focus again when the widget reopens after a capture.
const keepFocus = event => {
  if (!dialogRef.value.contains(event.target)) dialogRef.value.focus();
};

onMounted(async () => {
  // Focus leaves the chat input, so typed keys and Escape do not reach the composer. It goes
  // back there when the editor closes, so the next typed text is not lost.
  previousFocus = document.activeElement;
  dialogRef.value.focus();
  document.addEventListener('focusin', keepFocus);
  let bitmap;
  try {
    bitmap = await createImageBitmap(props.file);
  } catch {
    // A format the browser cannot decode, such as HEIC, is sent as it is.
    if (!isUnmounted) emit('save', props.file);
    return;
  }
  // The visitor can close the editor while a large image is still decoding.
  if (isUnmounted) {
    bitmap.close();
    return;
  }
  image.value = bitmap;
  commit();
});

onBeforeUnmount(() => {
  isUnmounted = true;
  document.removeEventListener('focusin', keepFocus);
  if (previousFocus?.isConnected) previousFocus.focus();
  image.value?.close();
});
</script>

<template>
  <Teleport to="body">
    <div :class="{ dark: isDark }">
      <div
        ref="dialogRef"
        tabindex="-1"
        class="fixed inset-0 z-50 flex flex-col outline-none bg-n-background text-n-slate-12"
        role="dialog"
        aria-modal="true"
        :aria-label="t('IMAGE_EDITOR.TITLE')"
        @keydown.stop="onKeydown"
        @keypress.stop
      >
        <div
          class="flex items-center justify-between gap-2 px-2 py-2 border-b border-n-weak"
        >
          <div class="flex items-center gap-1">
            <button
              v-for="tool in tools"
              :key="tool.id"
              type="button"
              class="flex items-center justify-center h-9 gap-1.5 px-2 text-sm rounded-lg min-w-9 transition-colors"
              :class="
                activeTool === tool.id
                  ? 'bg-n-alpha-2 text-n-ruby-9'
                  : 'hover:bg-n-alpha-1'
              "
              :aria-label="tool.label"
              :title="tool.label"
              :aria-pressed="activeTool === tool.id"
              @click="activeTool = tool.id"
            >
              <span class="size-5" :class="tool.icon" />
              <span class="hidden sm:inline">{{ tool.label }}</span>
            </button>
          </div>
          <div class="flex items-center gap-1">
            <button
              type="button"
              class="flex items-center justify-center rounded-lg size-9 hover:bg-n-alpha-1 disabled:opacity-40 disabled:hover:bg-transparent"
              :aria-label="t('IMAGE_EDITOR.UNDO')"
              :title="t('IMAGE_EDITOR.UNDO')"
              :disabled="!canUndo"
              @click="undo"
            >
              <span class="i-lucide-undo-2 size-5" />
            </button>
            <button
              type="button"
              class="flex items-center justify-center rounded-lg size-9 hover:bg-n-alpha-1 disabled:opacity-40 disabled:hover:bg-transparent"
              :aria-label="t('IMAGE_EDITOR.REDO')"
              :title="t('IMAGE_EDITOR.REDO')"
              :disabled="!canRedo"
              @click="redo"
            >
              <span class="i-lucide-redo-2 size-5" />
            </button>
          </div>
        </div>
        <div
          class="flex items-center justify-center flex-1 min-h-0 p-3 bg-n-alpha-1"
        >
          <canvas
            ref="canvasRef"
            class="max-w-full max-h-full shadow-md touch-none cursor-crosshair"
            @pointerdown="onPointerDown"
            @pointermove="onPointerMove"
            @pointerup="onPointerUp"
            @pointercancel="onPointerCancel"
          />
        </div>
        <div
          class="flex items-center justify-end gap-2 px-3 py-3 border-t border-n-weak"
        >
          <p
            v-if="exportError"
            role="alert"
            class="me-auto text-sm text-n-ruby-11"
          >
            {{ exportError }}
          </p>
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium rounded-lg hover:bg-n-alpha-2"
            @click="emit('cancel')"
          >
            {{ t('IMAGE_EDITOR.CANCEL') }}
          </button>
          <button
            type="button"
            class="px-4 py-2 text-sm font-medium rounded-lg disabled:opacity-60"
            :class="confirmClass"
            :disabled="isSaving"
            @click="save"
          >
            {{ confirmLabel || t('IMAGE_EDITOR.SEND') }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
