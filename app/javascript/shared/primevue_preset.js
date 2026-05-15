// CUSTOMIZAÇÃO_SYNAPSEOS
// PrimeVue preset customizado — mapeia o tema Aura para os tokens Synapse OS
// via CSS vars (_synapseos_tokens.scss). Componentes PrimeVue (DataTable,
// Chart, Dialog, Button, Select) herdam o branding sem cada um precisar ser
// re-estilizado via classes Tailwind.
//
// Como o branding evolui: alterar SOMENTE `_synapseos_tokens.scss`. Como os
// valores aqui são `rgb(var(--s-*))`, qualquer mudança nas CSS vars propaga
// pra todos os componentes PrimeVue automaticamente.
//
// Light/dark: as próprias CSS vars já alternam via `body.dark`, então os
// blocos `colorScheme.light` e `colorScheme.dark` referenciam as mesmas vars
// — PrimeVue só precisa de ambos os blocos definidos pra ativar o switch via
// `darkModeSelector: '.dark'` (config em entrypoints/dashboard.js).
import { definePreset } from '@primevue/themes';
import Aura from '@primevue/themes/aura';

const v = name => `rgb(var(${name}))`;

const sharedScheme = {
  primary: {
    color: v('--s-brand-cta'),
    contrastColor: v('--s-text-inverse'),
    hoverColor: v('--s-brand-cta-hover'),
    activeColor: v('--s-brand-cta-active'),
  },
  highlight: {
    background: v('--s-brand-soft'),
    focusBackground: v('--s-brand-soft-hover'),
    color: v('--s-brand-text'),
    focusColor: v('--s-brand-text'),
  },
  surface: {
    0: v('--s-surface'),
    50: v('--s-bg'),
    100: v('--s-subtle'),
    200: v('--s-border-subtle'),
    300: v('--s-border'),
    400: v('--s-border-strong'),
    500: v('--s-text-muted'),
    600: v('--s-text-secondary'),
    700: v('--s-text-primary'),
    800: v('--s-sidebar'),
    900: v('--s-sidebar'),
    950: v('--s-sidebar'),
  },
  formField: {
    background: v('--s-surface'),
    borderColor: v('--s-border'),
    hoverBorderColor: v('--s-border-strong'),
    focusBorderColor: v('--s-focus'),
    placeholderColor: v('--s-text-disabled'),
    color: v('--s-text-primary'),
  },
  content: {
    background: v('--s-surface'),
    hoverBackground: v('--s-subtle'),
    borderColor: v('--s-border'),
    color: v('--s-text-primary'),
    hoverColor: v('--s-text-primary'),
  },
  text: {
    color: v('--s-text-primary'),
    hoverColor: v('--s-text-primary'),
    mutedColor: v('--s-text-muted'),
    hoverMutedColor: v('--s-text-secondary'),
  },
};

export const SynapseOSPreset = definePreset(Aura, {
  semantic: {
    // Paleta primary alinhada com a Synka oficial (Manual 2026):
    // Deep Blue #1A2B4D, Medium #2E5C99, Electric #5DADE2, Light #F5F8FB.
    // As CSS vars dessas cores estão em `_synapseos_tokens.scss`.
    primary: {
      50: v('--s-brand-soft'),
      100: v('--s-brand-soft-hover'),
      200: v('--s-accent-100'),
      300: v('--s-accent-500'),
      400: v('--s-accent'),
      500: v('--s-brand-700'),
      600: v('--s-brand-cta'),
      700: v('--s-brand-800'),
      800: v('--s-brand-900'),
      900: v('--s-brand-900'),
      950: v('--s-brand-900'),
    },
    colorScheme: {
      light: sharedScheme,
      dark: sharedScheme,
    },
  },
  components: {
    button: {
      root: { borderRadius: '0.5rem' },
    },
    card: {
      root: {
        borderRadius: '1rem',
        background: v('--s-surface'),
        borderColor: v('--s-border'),
        color: v('--s-text-primary'),
        shadow: 'var(--s-shadow-md)',
      },
      body: { padding: '1.5rem' },
      title: { fontSize: '1rem', fontWeight: '600' },
    },
    datatable: {
      headerCell: {
        background: v('--s-bg'),
        color: v('--s-text-muted'),
        borderColor: v('--s-border'),
      },
      bodyCell: {
        borderColor: v('--s-border-subtle'),
      },
      row: {
        background: v('--s-surface'),
        hoverBackground: v('--s-subtle'),
        stripedBackground: v('--s-bg'),
      },
    },
    dialog: {
      root: {
        borderRadius: '1rem',
        background: v('--s-surface'),
        borderColor: v('--s-border'),
        color: v('--s-text-primary'),
        shadow: 'var(--s-shadow-lg)',
      },
      header: { padding: '1.25rem 1.5rem 1rem' },
      title: { fontSize: '1rem', fontWeight: '600' },
      content: { padding: '0.5rem 1.5rem 1.25rem' },
    },
    tag: {
      root: {
        borderRadius: '9999px',
        fontWeight: '500',
        padding: '0.125rem 0.625rem',
      },
    },
  },
});

export default SynapseOSPreset;
