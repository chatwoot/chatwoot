import { EditorState, Selection } from '@chatwoot/prosemirror-schema';
import { Schema } from 'prosemirror-model';
import { releasedSearchTransaction } from '../editorHelper';

const schema = new Schema({
  nodes: {
    doc: { content: 'paragraph+' },
    paragraph: { content: 'text*', toDOM: () => ['p', 0] },
    text: {},
  },
});

// A paragraph holding `text`, with the caret at `caret`, or at its end, where typing leaves it.
const stateWith = (text, caret) => {
  const doc = schema.node('doc', null, [
    schema.node('paragraph', null, text ? [schema.text(text)] : []),
  ]);
  const selection =
    caret === undefined
      ? Selection.atEnd(doc)
      : Selection.near(doc.resolve(caret));
  return EditorState.create({ schema, doc, selection });
};

const typing = (state, transaction, typed) => {
  const released = state.apply(transaction);
  return released.apply(released.tr.insertText(typed)).doc.textContent;
};

const textAfter = (state, transaction) =>
  state.apply(transaction).doc.textContent;

describe('releasedSearchTransaction', () => {
  it('puts what was typed in the picker where the caret is', () => {
    const state = stateWith('Estava com: {{');
    const range = { from: 13, to: 15 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contato.apelido',
    });

    expect(textAfter(state, transaction)).toBe('Estava com: {{contato.apelido');
  });

  it('adds after a variable that came from the document, keeping its braces', () => {
    const state = stateWith('Tab: {{conversation.before.assignee.name}}');
    const range = { from: 6, to: 43 };

    const transaction = releasedSearchTransaction(state, range, {
      text: ' ok',
    });

    expect(textAfter(state, transaction)).toBe(
      'Tab: {{conversation.before.assignee.name}} ok'
    );
  });

  it('replaces the document part the search was edited into, keeping the closing braces', () => {
    const state = stateWith('Oi {{contact.na}}');
    const range = { from: 4, to: 18 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contact.x',
      replace: true,
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.x}}');
  });

  it('keeps the braces and the punctuation after the variable it replaces', () => {
    const state = stateWith('Oi {{contact.name}}, tudo bem');
    const range = { from: 4, to: 21 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contact.x',
      replace: true,
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.x}}, tudo bem');
  });

  it('keeps the punctuation after a variable that was never closed', () => {
    const state = stateWith('Oi {{contact.na, ok');
    const range = { from: 4, to: 17 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contact.x',
      replace: true,
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.x, ok');
  });

  it('leaves the caret before the kept braces, so typing goes on inside the variable', () => {
    const state = stateWith('Oi {{contact.na}}');
    const range = { from: 4, to: 18 };

    const replaced = state.apply(
      releasedSearchTransaction(state, range, {
        text: 'contact.x',
        replace: true,
      })
    );

    expect(replaced.apply(replaced.tr.insertText('yz')).doc.textContent).toBe(
      'Oi {{contact.xyz}}'
    );
  });

  it('leaves the caret after what was handed back at the caret', () => {
    const state = stateWith('Oi {{');

    const released = state.apply(
      releasedSearchTransaction(state, { from: 4, to: 6 }, { text: 'contato' })
    );

    expect(
      released.apply(released.tr.insertText('.apelido}}')).doc.textContent
    ).toBe('Oi {{contato.apelido}}');
  });

  it('adds what was typed to the end of the variable when the caret sat inside it', () => {
    // Caret before `name`: the search showed `contact.name` and the letter went after it.
    const state = stateWith('Oi {{contact.name}}', 14);
    const range = { from: 4, to: 20 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'x',
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.namex}}');
    expect(typing(state, transaction, 'y')).toBe('Oi {{contact.namexy}}');
  });

  it('goes on after the variable when the caret sat past its braces, before punctuation', () => {
    const state = stateWith('Oi {{contact.name}}, ok', 20);
    const range = { from: 4, to: 21 };

    const transaction = releasedSearchTransaction(state, range, {
      text: '!',
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.name}}!, ok');
  });

  it('lets a brace typed in the search close the variable in place of its own', () => {
    const state = stateWith('Oi {{contact.name}}, ok');
    const range = { from: 4, to: 21 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contact.email}',
      replace: true,
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.email}, ok');
    // The picker has let go, so the second brace is typed in the editor.
    expect(typing(state, transaction, '}')).toBe('Oi {{contact.email}}, ok');
  });

  it('does not double the braces when the search came with both', () => {
    const state = stateWith('Oi {{contact.name}}');
    const range = { from: 4, to: 20 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contact.email}}',
      replace: true,
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.email}}');
  });

  it('closes the variable once when the brace was typed after its content', () => {
    const state = stateWith('Oi {{contact.name}}', 14);
    const range = { from: 4, to: 20 };

    const transaction = releasedSearchTransaction(state, range, {
      text: '}',
    });

    expect(typing(state, transaction, '}')).toBe('Oi {{contact.name}}');
  });

  it('keeps the sentence punctuation outside the variable it replaces', () => {
    const state = stateWith('Oi {{contact.name}}.');
    const range = { from: 4, to: 21 };

    const transaction = releasedSearchTransaction(state, range, {
      text: 'contact.nme',
      replace: true,
    });

    expect(textAfter(state, transaction)).toBe('Oi {{contact.nme}}.');
  });

  it('does nothing when nothing was typed', () => {
    const state = stateWith('Oi {{');

    expect(
      releasedSearchTransaction(state, { from: 4, to: 6 }, { text: '' })
    ).toBeNull();
  });

  describe('after a trigger other than `{{`', () => {
    it('goes on after a slash typed as punctuation in a sentence', () => {
      const state = stateWith(
        'Estava com: {{conversation.before.assignee.name}} /'
      );
      const range = { from: 51, to: 52 };

      const transaction = releasedSearchTransaction(
        state,
        range,
        { text: ' Agora com: ' },
        '/'
      );

      expect(textAfter(state, transaction)).toBe(
        'Estava com: {{conversation.before.assignee.name}} / Agora com: '
      );
    });

    it('adds what was typed to the end of the token when the caret sat inside it', () => {
      const state = stateWith('Oi /sau fim', 6);
      const range = { from: 4, to: 8 };

      const transaction = releasedSearchTransaction(
        state,
        range,
        { text: 'x' },
        '/'
      );

      expect(textAfter(state, transaction)).toBe('Oi /saux fim');
    });

    it('replaces the whole token with an edited search, braces and all', () => {
      const state = stateWith('Oi @joa}} ok');
      const range = { from: 4, to: 10 };

      const transaction = releasedSearchTransaction(
        state,
        range,
        { text: 'maria', replace: true },
        '@'
      );

      expect(textAfter(state, transaction)).toBe('Oi @maria ok');
    });
  });
});
