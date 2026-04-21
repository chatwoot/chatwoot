// CUSTOMIZAÇÃO_SYNAPSEOS
// PrimeVue preset customizado — mapeia o tema Aura para os tokens Synapse
// OS via CSS vars. Componentes PrimeVue (DataTable, Chart, Dialog, Button,
// Select) herdam o visual sem cada um precisar ser re-estilizado via
// classes Tailwind.
import { definePreset } from '@primevue/themes';
import Aura from '@primevue/themes/aura';

export const SynapseOSPreset = definePreset(Aura, {
  semantic: {
    primary: {
      50: '#E3F2FD',
      100: '#BBDEFB',
      200: '#90CAF9',
      300: '#64B5F6',
      400: '#42A5F5',
      500: '#2196F3', // brand
      600: '#1E88E5', // CTA sólido
      700: '#1976D2',
      800: '#1565C0',
      900: '#0D47A1',
      950: '#0A3A7A',
    },
    colorScheme: {
      light: {
        primary: {
          color: '{primary.600}',
          contrastColor: '#FFFFFF',
          hoverColor: '{primary.700}',
          activeColor: '{primary.800}',
        },
        highlight: {
          background: '{primary.50}',
          focusBackground: '{primary.100}',
          color: '{primary.700}',
          focusColor: '{primary.700}',
        },
        surface: {
          0: '#FFFFFF',
          50: '#F8FAFC',
          100: '#F1F5F9',
          200: '#E2E8F0',
          300: '#CBD5E1',
          400: '#94A3B8',
          500: '#64748B',
          600: '#475569',
          700: '#334155',
          800: '#1E293B',
          900: '#0F172A',
          950: '#020617',
        },
        formField: {
          background: '#FFFFFF',
          borderColor: '#E2E8F0',
          hoverBorderColor: '#CBD5E1',
          focusBorderColor: '{primary.500}',
          placeholderColor: '#94A3B8',
          color: '#0F172A',
        },
        content: {
          background: '#FFFFFF',
          hoverBackground: '#F8FAFC',
          borderColor: '#E2E8F0',
          color: '#0F172A',
          hoverColor: '#0F172A',
        },
        text: {
          color: '#0F172A',
          hoverColor: '#0F172A',
          mutedColor: '#64748B',
          hoverMutedColor: '#475569',
        },
      },
    },
  },
  components: {
    button: {
      root: {
        borderRadius: '0.5rem',
      },
    },
    card: {
      root: {
        borderRadius: '1rem',
        background: '#FFFFFF',
        borderColor: '#E2E8F0',
        color: '#0F172A',
        shadow: 'var(--s-shadow-md)',
      },
      body: { padding: '1.5rem' },
      title: {
        fontSize: '1rem',
        fontWeight: '600',
      },
    },
    datatable: {
      headerCell: {
        background: '#F8FAFC',
        color: '#64748B',
        borderColor: '#E2E8F0',
      },
      bodyCell: {
        borderColor: '#F1F5F9',
      },
      row: {
        background: '#FFFFFF',
        hoverBackground: '#F1F5F9',
        stripedBackground: '#F8FAFC',
      },
    },
    dialog: {
      root: {
        borderRadius: '1rem',
        shadow: 'var(--s-shadow-lg)',
      },
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
