import { computed } from 'vue';
import { useStore } from 'vuex';

export function useCsatRequest() {
  const store = useStore();
  const conversationSize = computed(
    () => store.getters['conversation/getConversationSize']
  );

  const canRequestCsat = computed(
    () =>
      conversationSize.value > 0 &&
      window.chatwootWebChannel?.csatSurveyEnabled &&
      window.chatwootWebChannel?.csatDisplayType === 'like_dislike'
  );

  return { canRequestCsat };
}
