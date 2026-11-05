import { useCommandBar } from '@chatwoot/jumpbar';

// ninja-keys stays mounted until command_bar_v2 ships; both bars use the same page ids.
export const openCommandBar = ({ page }) => {
  const ninja = document.querySelector('ninja-keys');
  if (ninja) {
    ninja.open({ parent: page });
    return;
  }
  useCommandBar().open({ page });
};
