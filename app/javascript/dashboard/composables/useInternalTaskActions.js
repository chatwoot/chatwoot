import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';

export function useInternalTaskActions(taskRef, conversationIdRef, onUpdated) {
  const { t } = useI18n();
  const store = useStore();
  const uiFlags = useMapGetter('internalTasks/getUIFlags');

  const isTerminal = computed(() => {
    const task = taskRef.value;
    return task && ['completed', 'cancelled'].includes(task.status);
  });

  const primaryAction = computed(() => {
    const task = taskRef.value;
    if (!task || isTerminal.value) return null;
    if (!task.assignedToId) {
      return {
        key: 'claimTask',
        label: t('INTERNAL_TASKS.ACTIONS.ASSIGN_TO_ME'),
        color: 'blue',
      };
    }
    if (task.status === 'pending') {
      return {
        key: 'startTask',
        label: t('INTERNAL_TASKS.ACTIONS.START'),
        color: 'blue',
      };
    }
    if (['in_progress', 'blocked', 'waiting_external'].includes(task.status)) {
      return {
        key: 'completeTask',
        label: t('INTERNAL_TASKS.ACTIONS.COMPLETE'),
        color: 'teal',
      };
    }
    return null;
  });

  const runAction = async action => {
    const task = taskRef.value;
    if (!task) return;
    const conversationId =
      conversationIdRef?.value ?? task.conversation?.id ?? task.conversationId;
    try {
      await store.dispatch(`internalTasks/${action}`, {
        taskId: task.id,
        conversationId,
      });
      onUpdated?.();
    } catch (error) {
      if (action === 'claimTask' && error?.response?.status === 409) {
        useAlert(t('INTERNAL_TASKS.ERRORS.ALREADY_CLAIMED'));
        onUpdated?.();
        return;
      }
      throw error;
    }
  };

  return { uiFlags, isTerminal, primaryAction, runAction };
}
