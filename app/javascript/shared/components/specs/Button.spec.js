import { mount } from '@vue/test-utils';
import Button from '../Button.vue';

describe('Button', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(Button, {
      props,
      slots: {
        default: 'Click me',
      },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
  });

  describe('rendering', () => {
    it('renders button with default props', () => {
      createComponent();

      expect(wrapper.find('button').exists()).toBe(true);
      expect(wrapper.text()).toBe('Click me');
      expect(wrapper.classes()).toContain('bg-woot-500');
      expect(wrapper.classes()).toContain('hover:bg-woot-700');
    });

    it('renders button with custom slot content', () => {
      wrapper = mount(Button, {
        slots: {
          default: '<span>Custom Content</span>',
        },
      });

      expect(wrapper.html()).toContain('<span>Custom Content</span>');
    });

    it('matches snapshot with default props', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('props', () => {
    it('applies block class when block prop is true', () => {
      createComponent({ block: true });

      expect(wrapper.classes()).toContain('w-full');
    });

    it('does not apply block class when block prop is false', () => {
      createComponent({ block: false });

      expect(wrapper.classes()).not.toContain('w-full');
    });

    it('applies clear type styling', () => {
      createComponent({ type: 'clear' });

      expect(wrapper.classes()).toContain('text-black-600');
      expect(wrapper.classes()).toContain('text-xs');
      expect(wrapper.classes()).not.toContain('bg-woot-500');
    });

    it('applies blue type styling by default', () => {
      createComponent({ type: 'blue' });

      expect(wrapper.classes()).toContain('bg-woot-500');
      expect(wrapper.classes()).toContain('hover:bg-woot-700');
    });

    it('applies custom background color when bgColor prop is provided', () => {
      createComponent({ bgColor: '#ff0000' });

      expect(wrapper.attributes('style')).toContain(
        'background-color: rgb(255, 0, 0)'
      );
    });

    it('applies custom text color when textColor prop is provided', () => {
      createComponent({ textColor: '#00ff00' });

      expect(wrapper.attributes('style')).toContain('color: rgb(0, 255, 0)');
    });

    it('applies both custom colors when both props are provided', () => {
      createComponent({
        bgColor: '#ff0000',
        textColor: '#00ff00',
      });

      const style = wrapper.attributes('style');
      expect(style).toContain('background-color: rgb(255, 0, 0)');
      expect(style).toContain('color: rgb(0, 255, 0)');
    });

    it('sets disabled attribute when disabled prop is true', () => {
      createComponent({ disabled: true });

      expect(wrapper.attributes('disabled')).toBeDefined();
      expect(wrapper.classes()).toContain('disabled:opacity-50');
    });

    it('does not set disabled attribute when disabled prop is false', () => {
      createComponent({ disabled: false });

      expect(wrapper.attributes('disabled')).toBeUndefined();
    });
  });

  describe('computed properties', () => {
    it('computes buttonClassName correctly for default blue type', () => {
      createComponent({ type: 'blue' });

      const expectedClasses = [
        'text-white',
        'py-3',
        'px-4',
        'rounded-lg',
        'shadow-sm',
        'leading-4',
        'cursor-pointer',
        'disabled:opacity-50',
        'bg-woot-500',
        'hover:bg-woot-700',
      ];

      expectedClasses.forEach(className => {
        expect(wrapper.classes()).toContain(className);
      });
    });

    it('computes buttonClassName correctly for clear type', () => {
      createComponent({ type: 'clear' });

      const expectedClasses = [
        'flex',
        'mx-auto',
        'mt-4',
        'text-xs',
        'leading-3',
        'w-auto',
        'text-black-600',
      ];

      expectedClasses.forEach(className => {
        expect(wrapper.classes()).toContain(className);
      });
    });

    it('computes buttonStyles correctly when custom colors are provided', () => {
      createComponent({
        bgColor: '#123456',
        textColor: '#abcdef',
      });

      const computedStyles = wrapper.vm.buttonStyles;
      expect(computedStyles.backgroundColor).toBe('#123456');
      expect(computedStyles.color).toBe('#abcdef');
    });

    it('returns empty buttonStyles when no custom colors are provided', () => {
      createComponent();

      const computedStyles = wrapper.vm.buttonStyles;
      expect(Object.keys(computedStyles)).toHaveLength(0);
    });
  });

  describe('accessibility', () => {
    it('maintains button semantics', () => {
      createComponent();

      expect(wrapper.element.tagName).toBe('BUTTON');
    });

    it('supports disabled state for screen readers', () => {
      createComponent({ disabled: true });

      expect(wrapper.attributes('disabled')).toBeDefined();
    });
  });

  describe('edge cases', () => {
    it('handles empty slot content gracefully', () => {
      wrapper = mount(Button, {
        slots: {
          default: '',
        },
      });

      expect(wrapper.text()).toBe('');
      expect(wrapper.find('button').exists()).toBe(true);
    });

    it('handles undefined props gracefully', () => {
      createComponent({
        bgColor: undefined,
        textColor: undefined,
        type: undefined,
      });

      expect(wrapper.find('button').exists()).toBe(true);
      // Should fall back to default blue styling
      expect(wrapper.classes()).toContain('bg-woot-500');
    });

    it('handles custom type that is not clear or blue', () => {
      createComponent({ type: 'custom' });

      // Should not apply blue styling when custom colors are not provided
      expect(wrapper.classes()).toContain('text-white');
      expect(wrapper.classes()).not.toContain('bg-woot-500');
    });
  });
});
