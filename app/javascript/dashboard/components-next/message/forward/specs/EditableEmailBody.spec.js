import { mount } from '@vue/test-utils';
import EditableEmailBody from '../EditableEmailBody.vue';

Object.defineProperty(HTMLElement.prototype, 'innerText', {
  configurable: true,
  get() {
    return this.textContent;
  },
});

describe('EditableEmailBody', () => {
  beforeEach(() => {
    document.execCommand = vi.fn();
  });

  it('renders the html as an editable document', () => {
    const wrapper = mount(EditableEmailBody, {
      props: { html: '<p>Hello <b>there</b></p>' },
    });
    const editable = wrapper.find('[contenteditable="true"]');

    expect(editable.exists()).toBe(true);
    expect(editable.html()).toContain('<p>Hello <b>there</b></p>');
  });

  it('returns the current html and text after edits', () => {
    const wrapper = mount(EditableEmailBody, {
      props: { html: '<p>Hello</p>' },
    });

    wrapper.find('[contenteditable="true"]').element.innerHTML =
      '<p>Edited</p> ';

    expect(wrapper.vm.getContent()).toEqual({
      html: '<p>Edited</p> ',
      text: 'Edited',
    });
  });

  it('focuses the document before running the browser undo', () => {
    const wrapper = mount(EditableEmailBody, {
      props: { html: '<p>Hello</p>' },
      attachTo: document.body,
    });

    wrapper.vm.undo();

    expect(document.activeElement).toBe(
      wrapper.find('[contenteditable="true"]').element
    );
    expect(document.execCommand).toHaveBeenCalledWith('undo');
    wrapper.unmount();
  });
});
