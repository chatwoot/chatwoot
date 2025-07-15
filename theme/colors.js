const {
  blue,
  blueDark,
  green,
  greenDark,
  yellow,
  yellowDark,
  slate,
  slateDark,
  red,
  redDark,
  violet,
  violetDark,
} = require('@radix-ui/colors');

const colors = {
  // Tema principal alterado para roxo escuro
  woot: {
    25: '#faf8ff',    // Roxo muito claro
    50: '#f0ebff',    // Roxo claro
    75: '#e5d9ff',    // Roxo suave
    100: '#d6c7ff',   // Roxo claro médio
    200: '#b794f6',   // Roxo médio
    300: '#9f7aea',   // Roxo
    400: '#805ad5',   // Roxo escuro
    500: '#6b46c1',   // Roxo principal
    600: '#553c9a',   // Roxo escuro
    700: '#44337a',   // Roxo muito escuro
    800: '#322659',   // Roxo quase preto
    900: '#1a1625',   // Roxo escuro profundo
  },
  // Verde como cor complementar (para sucesso/confirmações)
  green: {
    50: '#f0fdf4',
    100: '#dcfce7',
    200: '#bbf7d0',
    300: '#86efac',
    400: '#4ade80',
    500: '#22c55e',
    600: '#16a34a',
    700: '#15803d',
    800: '#166534',
    900: '#14532d',
  },
  // Verde específico para mensagens privadas
  'private-green': {
    50: '#f0fdf4',    // Fundo muito claro
    100: '#dcfce7',   // Fundo claro
    200: '#bbf7d0',   // Fundo hover
    400: '#4ade80',   // Borda tracejada
    600: '#16a34a',   // Texto meta e botão
    700: '#15803d',   // Botão hover
    800: '#166534',   // Texto principal
  },
  // Roxo específico para mensagens recebidas (usuários)
  'user-purple': {
    50: '#faf8ff',    // Fundo muito claro
    100: '#f3f0ff',   // Fundo claro
    200: '#e9e5ff',   // Fundo hover
    300: '#d1c7ff',   // Roxo suave
    800: '#5b21b6',   // Texto principal
    900: '#4c1d95',   // Texto escuro
  },
  // Dourado como segunda cor complementar (para highlights/warnings)
  gold: {
    50: '#fffbeb',
    100: '#fef3c7',
    200: '#fde68a',
    300: '#fcd34d',
    400: '#fbbf24',
    500: '#f59e0b',
    600: '#d97706',
    700: '#b45309',
    800: '#92400e',
    900: '#78350f',
  },
  yellow: {
    50: '#fffbeb',
    100: '#fef3c7',
    200: '#fde68a',
    300: '#fcd34d',
    400: '#fbbf24',
    500: '#f59e0b',
    600: '#d97706',
    700: '#b45309',
    800: '#92400e',
    900: '#78350f',
  },
  slate: {
    25: '#fafafa',
    50: '#f8fafc',
    75: '#f1f5f9',
    100: '#e2e8f0',
    200: '#cbd5e1',
    300: '#94a3b8',
    400: '#64748b',
    500: '#475569',
    600: '#334155',
    700: '#1e293b',
    800: '#0f172a',
    900: '#020617',
  },
  black: {
    50: '#fafafa',
    100: '#020617',
    200: '#cbd5e1',
    300: '#94a3b8',
    400: '#64748b',
    500: '#475569',
    600: '#334155',
    700: '#1e293b',
    800: '#0f172a',
    900: '#020617',
  },
  red: {
    50: '#fef2f2',
    100: '#fee2e2',
    200: '#fecaca',
    300: '#fca5a5',
    400: '#f87171',
    500: '#ef4444',
    600: '#dc2626',
    700: '#b91c1c',
    800: '#991b1b',
    900: '#7f1d1d',
  },
  violet: {
    50: '#f8f6ff',
    100: '#f0ebff',
    200: '#e5d9ff',
    300: '#d6c7ff',
    400: '#b794f6',
    500: '#9f7aea',
    600: '#805ad5',
    700: '#6b46c1',
    800: '#553c9a',
    900: '#44337a',
  },

  // next design system color - Atualizando para tema roxo
  n: {
    slate: {
      1: 'rgb(var(--slate-1) / <alpha-value>)',
      2: 'rgb(var(--slate-2) / <alpha-value>)',
      3: 'rgb(var(--slate-3) / <alpha-value>)',
      4: 'rgb(var(--slate-4) / <alpha-value>)',
      5: 'rgb(var(--slate-5) / <alpha-value>)',
      6: 'rgb(var(--slate-6) / <alpha-value>)',
      7: 'rgb(var(--slate-7) / <alpha-value>)',
      8: 'rgb(var(--slate-8) / <alpha-value>)',
      9: 'rgb(var(--slate-9) / <alpha-value>)',
      10: 'rgb(var(--slate-10) / <alpha-value>)',
      11: 'rgb(var(--slate-11) / <alpha-value>)',
      12: 'rgb(var(--slate-12) / <alpha-value>)',
    },

    iris: {
      1: 'rgb(var(--iris-1) / <alpha-value>)',
      2: 'rgb(var(--iris-2) / <alpha-value>)',
      3: 'rgb(var(--iris-3) / <alpha-value>)',
      4: 'rgb(var(--iris-4) / <alpha-value>)',
      5: 'rgb(var(--iris-5) / <alpha-value>)',
      6: 'rgb(var(--iris-6) / <alpha-value>)',
      7: 'rgb(var(--iris-7) / <alpha-value>)',
      8: 'rgb(var(--iris-8) / <alpha-value>)',
      9: 'rgb(var(--iris-9) / <alpha-value>)',
      10: 'rgb(var(--iris-10) / <alpha-value>)',
      11: 'rgb(var(--iris-11) / <alpha-value>)',
      12: 'rgb(var(--iris-12) / <alpha-value>)',
    },

    // Roxo como cor principal ao invés de azul
    purple: {
      1: 'rgb(var(--purple-1) / <alpha-value>)',
      2: 'rgb(var(--purple-2) / <alpha-value>)',
      3: 'rgb(var(--purple-3) / <alpha-value>)',
      4: 'rgb(var(--purple-4) / <alpha-value>)',
      5: 'rgb(var(--purple-5) / <alpha-value>)',
      6: 'rgb(var(--purple-6) / <alpha-value>)',
      7: 'rgb(var(--purple-7) / <alpha-value>)',
      8: 'rgb(var(--purple-8) / <alpha-value>)',
      9: 'rgb(var(--purple-9) / <alpha-value>)',
      10: 'rgb(var(--purple-10) / <alpha-value>)',
      11: 'rgb(var(--purple-11) / <alpha-value>)',
      12: 'rgb(var(--purple-12) / <alpha-value>)',
    },

    blue: {
      1: 'rgb(var(--blue-1) / <alpha-value>)',
      2: 'rgb(var(--blue-2) / <alpha-value>)',
      3: 'rgb(var(--blue-3) / <alpha-value>)',
      4: 'rgb(var(--blue-4) / <alpha-value>)',
      5: 'rgb(var(--blue-5) / <alpha-value>)',
      6: 'rgb(var(--blue-6) / <alpha-value>)',
      7: 'rgb(var(--blue-7) / <alpha-value>)',
      8: 'rgb(var(--blue-8) / <alpha-value>)',
      9: 'rgb(var(--blue-9) / <alpha-value>)',
      10: 'rgb(var(--blue-10) / <alpha-value>)',
      11: 'rgb(var(--blue-11) / <alpha-value>)',
      12: 'rgb(var(--blue-12) / <alpha-value>)',
    },

    ruby: {
      1: 'rgb(var(--ruby-1) / <alpha-value>)',
      2: 'rgb(var(--ruby-2) / <alpha-value>)',
      3: 'rgb(var(--ruby-3) / <alpha-value>)',
      4: 'rgb(var(--ruby-4) / <alpha-value>)',
      5: 'rgb(var(--ruby-5) / <alpha-value>)',
      6: 'rgb(var(--ruby-6) / <alpha-value>)',
      7: 'rgb(var(--ruby-7) / <alpha-value>)',
      8: 'rgb(var(--ruby-8) / <alpha-value>)',
      9: 'rgb(var(--ruby-9) / <alpha-value>)',
      10: 'rgb(var(--ruby-10) / <alpha-value>)',
      11: 'rgb(var(--ruby-11) / <alpha-value>)',
      12: 'rgb(var(--ruby-12) / <alpha-value>)',
    },

    amber: {
      1: 'rgb(var(--amber-1) / <alpha-value>)',
      2: 'rgb(var(--amber-2) / <alpha-value>)',
      3: 'rgb(var(--amber-3) / <alpha-value>)',
      4: 'rgb(var(--amber-4) / <alpha-value>)',
      5: 'rgb(var(--amber-5) / <alpha-value>)',
      6: 'rgb(var(--amber-6) / <alpha-value>)',
      7: 'rgb(var(--amber-7) / <alpha-value>)',
      8: 'rgb(var(--amber-8) / <alpha-value>)',
      9: 'rgb(var(--amber-9) / <alpha-value>)',
      10: 'rgb(var(--amber-10) / <alpha-value>)',
      11: 'rgb(var(--amber-11) / <alpha-value>)',
      12: 'rgb(var(--amber-12) / <alpha-value>)',
    },

    teal: {
      1: 'rgb(var(--teal-1) / <alpha-value>)',
      2: 'rgb(var(--teal-2) / <alpha-value>)',
      3: 'rgb(var(--teal-3) / <alpha-value>)',
      4: 'rgb(var(--teal-4) / <alpha-value>)',
      5: 'rgb(var(--teal-5) / <alpha-value>)',
      6: 'rgb(var(--teal-6) / <alpha-value>)',
      7: 'rgb(var(--teal-7) / <alpha-value>)',
      8: 'rgb(var(--teal-8) / <alpha-value>)',
      9: 'rgb(var(--teal-9) / <alpha-value>)',
      10: 'rgb(var(--teal-10) / <alpha-value>)',
      11: 'rgb(var(--teal-11) / <alpha-value>)',
      12: 'rgb(var(--teal-12) / <alpha-value>)',
    },

    gray: {
      1: 'rgb(var(--gray-1) / <alpha-value>)',
      2: 'rgb(var(--gray-2) / <alpha-value>)',
      3: 'rgb(var(--gray-3) / <alpha-value>)',
      4: 'rgb(var(--gray-4) / <alpha-value>)',
      5: 'rgb(var(--gray-5) / <alpha-value>)',
      6: 'rgb(var(--gray-6) / <alpha-value>)',
      7: 'rgb(var(--gray-7) / <alpha-value>)',
      8: 'rgb(var(--gray-8) / <alpha-value>)',
      9: 'rgb(var(--gray-9) / <alpha-value>)',
      10: 'rgb(var(--gray-10) / <alpha-value>)',
      11: 'rgb(var(--gray-11) / <alpha-value>)',
      12: 'rgb(var(--gray-12) / <alpha-value>)',
    },

    black: '#000000',
    brand: '#6b46c1', // Roxo principal como cor da marca
    background: 'rgb(var(--background-color) / <alpha-value>)',
    solid: {
      1: 'rgb(var(--solid-1) / <alpha-value>)',
      2: 'rgb(var(--solid-2) / <alpha-value>)',
      3: 'rgb(var(--solid-3) / <alpha-value>)',
      active: 'rgb(var(--solid-active) / <alpha-value>)',
      amber: 'rgb(var(--solid-amber) / <alpha-value>)',
      purple: 'rgb(var(--solid-purple) / <alpha-value>)', // Adicionado roxo
      iris: 'rgb(var(--solid-iris) / <alpha-value>)',
    },
    alpha: {
      1: 'rgba(var(--alpha-1))',
      2: 'rgba(var(--alpha-2))',
      3: 'rgba(var(--alpha-3))',
      black1: 'rgba(var(--black-alpha-1))',
      black2: 'rgba(var(--black-alpha-2))',
      white: 'rgba(var(--white-alpha))',
    },
    weak: 'rgb(var(--border-weak) / <alpha-value>)',
    container: 'rgba(var(--border-container))',
    strong: 'rgb(var(--border-strong) / <alpha-value>)',
    'purple-border': 'rgba(var(--border-purple))', // Alterado de azul para roxo
    'purple-text': 'rgba(var(--text-purple))', // Alterado de azul para roxo
  },
};

module.exports = { colors };
