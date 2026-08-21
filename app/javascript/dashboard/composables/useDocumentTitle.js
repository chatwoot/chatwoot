import { computed, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';

/**
 * Mantém a contagem de não lidas no título da aba, no formato "(3) Desky-adm".
 *
 * O Rails renderiza <title> com INSTALLATION_NAME, então lemos esse valor uma
 * vez como base em vez de duplicar o nome da instalação aqui — trocar o nome no
 * super admin continua bastando, sem mexer no código.
 */
export function useDocumentTitle() {
  const store = useStore();
  const baseTitle = (document.title || '').trim();

  const unreadCount = computed(
    () => store.getters['notifications/getUnreadCount'] || 0
  );

  watch(
    unreadCount,
    count => {
      document.title = count > 0 ? `(${count}) ${baseTitle}` : baseTitle;
    },
    { immediate: true }
  );

  return { unreadCount };
}
