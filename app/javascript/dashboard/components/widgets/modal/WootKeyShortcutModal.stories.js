import WootKeyboardShortcutModal from './WootKeyShortcutModal.vue';

export default {
  title: 'Components/Shortcuts/Keyboard Shortcut',
  component: WootKeyboardShortcutModal,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { WootKeyboardShortcutModal },
  template:
    '<woot-keyboard-shortcut-modal v-bind="$props"></woot-keyboard-shortcut-modal>',
});

export const KeyboardShortcut = Template.bind({});
KeyboardShortcut.args = {};
