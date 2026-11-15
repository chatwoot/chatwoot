import {
  buildEditor,
  EditorState,
  EditorView,
  messageSchema,
} from '@chatwoot/prosemirror-schema';

// jsdom has no layout, so every box the floating menubar reads is set here.
// The scroll area starts at viewport y=200, below a fixed header, the way
// settings pages lay out their content.
const SCROLL_TOP = 200;
const MENU_HEIGHT = 36;

const rect = (top, bottom) => ({
  top,
  bottom,
  left: 0,
  right: 600,
  width: 600,
  height: bottom - top,
});

const mountFloatingEditor = () => {
  const scroller = document.createElement('div');
  const host = document.createElement('div');
  scroller.appendChild(host);
  document.body.appendChild(scroller);
  scroller.getBoundingClientRect = () => rect(SCROLL_TOP, 900);

  const view = new EditorView(host, {
    state: EditorState.create({
      schema: messageSchema,
      plugins: buildEditor({ schema: messageSchema }),
    }),
  });
  const wrapper = scroller.querySelector('.ProseMirror-menubar-wrapper');
  const menu = scroller.querySelector('.ProseMirror-menubar');
  Object.defineProperty(menu, 'offsetHeight', { value: MENU_HEIGHT });
  menu.getBoundingClientRect = () => rect(0, MENU_HEIGHT);

  const scrollEditorTo = (top, bottom) => {
    wrapper.getBoundingClientRect = () => rect(top, bottom);
    scroller.dispatchEvent(new Event('scroll'));
  };

  return { view, menu, scroller, scrollEditorTo };
};

describe('floating editor menubar inside a scroll container', () => {
  let mounted;

  afterEach(() => {
    mounted.view.destroy();
    mounted.scroller.remove();
  });

  it('pins to the top of the scroll area while the editor is still visible below it', () => {
    mounted = mountFloatingEditor();

    mounted.scrollEditorTo(150, 400);

    expect(mounted.menu.style.position).toBe('fixed');
    expect(mounted.menu.style.top).toBe(`${SCROLL_TOP}px`);
  });

  it('stops floating once the editor has scrolled above the scroll area', () => {
    mounted = mountFloatingEditor();
    mounted.scrollEditorTo(150, 400);

    // Entirely hidden under the header, yet still below viewport y=46.
    mounted.scrollEditorTo(60, 140);

    expect(mounted.menu.style.position).toBe('');
  });

  it('keeps floating while a strip of the editor shorter than the menu is still visible', () => {
    mounted = mountFloatingEditor();
    mounted.scrollEditorTo(150, 400);

    mounted.scrollEditorTo(-100, SCROLL_TOP + 20);

    expect(mounted.menu.style.position).toBe('fixed');
  });

  it('stops floating once less than 10px of the editor is visible', () => {
    mounted = mountFloatingEditor();
    mounted.scrollEditorTo(150, 400);

    mounted.scrollEditorTo(-100, SCROLL_TOP + 9);

    expect(mounted.menu.style.position).toBe('');
  });

  it('does not start floating for an editor already hidden above the scroll area', () => {
    mounted = mountFloatingEditor();

    mounted.scrollEditorTo(60, 140);

    expect(mounted.menu.style.position).toBe('');
  });
});
