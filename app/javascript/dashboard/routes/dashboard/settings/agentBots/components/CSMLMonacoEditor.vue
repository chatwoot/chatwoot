<script>
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { mapGetters } from 'vuex';

export default {
  components: { LoadingState },
  props: {
    modelValue: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  data() {
    return {
      iframeLoading: true,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    window.onmessage = e => {
      if (
        typeof e.data !== 'string' ||
        !e.data.startsWith('chatwoot-csml-editor:update')
      ) {
        return;
      }
      const csmlContent = e.data.replace('chatwoot-csml-editor:update', '');
      this.$emit('update:modelValue', csmlContent);
    };
  },
  methods: {
    onEditorLoad() {
      const frameElement = document.getElementById(`csml-editor--frame`);
      const eventData = {
        event: 'editorContext',
        data: this.modelValue || '',
      };
      frameElement.contentWindow.postMessage(JSON.stringify(eventData), '*');
      this.iframeLoading = false;
    },
  },
};
</script>

<template>
  <div class="csml-editor--container">
    <LoadingState
      v-if="iframeLoading"
      :message="$t('AGENT_BOTS.LOADING_EDITOR')"
      class="dashboard-app_loading-container"
    />
    <iframe
      id="csml-editor--frame"
      :src="globalConfig.csmlEditorHost"
      @load="onEditorLoad"
    />
  </div>
</template>

<style scoped>
#csml-editor--frame {
  border: 0;
  width: 100%;
  height: 100%;
}
</style>
