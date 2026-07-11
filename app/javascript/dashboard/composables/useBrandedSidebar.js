import { ref, computed, onMounted } from 'vue';
import { useMutationObserver } from '@vueuse/core';
import { useMapGetter } from 'dashboard/composables/store';

/**
 * Cor de marca EFETIVA da sidebar.
 *
 * O branding (sidebar azul + dropdowns sólidos) só deve valer no TEMA CLARO. O tema é aplicado
 * como a classe `dark` no `document.body` (ver dashboard/helper/themeHelper.js), então observamos
 * essa classe e zeramos a cor no escuro. Como todo o branding deriva desta cor
 * (hasBrandedSidebar, a var --sidebar-background-color, as classes .sidebar-branded /
 * .sidebar-branded-dropdown e o solid-surface dos dropdowns), gatear aqui desliga tudo de uma vez
 * no dark — sem cor de reserva hardcoded espalhada pelos componentes.
 */
export function useBrandedSidebar() {
  const globalConfig = useMapGetter('globalConfig/get');
  const isDarkMode = ref(false);

  const syncTheme = () => {
    isDarkMode.value = document.body.classList.contains('dark');
  };

  onMounted(syncTheme);
  useMutationObserver(document.body, syncTheme, {
    attributes: true,
    attributeFilter: ['class'],
  });

  const brandedColor = computed(() => {
    if (isDarkMode.value) return '';

    return globalConfig.value?.sidebarBackgroundColor?.trim() || '';
  });

  return { brandedColor };
}
