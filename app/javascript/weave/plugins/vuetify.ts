import 'vuetify/styles';
import { createVuetify } from 'vuetify';

const vuetify = createVuetify({
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
        dark: false,
        colors: {
          primary: '#8127E8',
          accent: '#FF6600',
        },
      },
      dark: {
        dark: true,
        colors: {
          primary: '#8127E8',
          accent: '#FF6600',
        },
      },
    },
  },
});

export default vuetify;

