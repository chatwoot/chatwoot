import {
  renderInlineDiff,
  buildDiffBlocks,
  hasPendingChanges,
  rendersIdentically,
} from '../articleDiffHelper';

describe('articleDiffHelper', () => {
  describe('renderInlineDiff', () => {
    it('returns the text unchanged when there is no difference', () => {
      const result = renderInlineDiff('hello world', 'hello world');
      expect(result).toBe('hello world');
      expect(result).not.toContain('<ins');
      expect(result).not.toContain('<del');
    });

    it('wraps inserted words in <ins>', () => {
      const result = renderInlineDiff('hello', 'hello there');
      expect(result).toContain('hello');
      expect(result).toContain('<ins');
      expect(result).toContain('there');
    });

    it('wraps removed words in <del>', () => {
      const result = renderInlineDiff('hello there', 'hello');
      expect(result).toContain('<del');
      expect(result).toContain('there');
    });

    it('keeps a single removal contiguous when a word repeats', () => {
      const result = renderInlineDiff(
        'How to use Agent bots?',
        'How How to Agent bots?'
      );
      expect(result).toBe(
        'How <ins class="!bg-n-teal-5 !text-n-teal-12 !no-underline rounded px-0.5">How</ins> to <del class="!bg-n-ruby-5 !text-n-ruby-12 !line-through rounded px-0.5">use</del> Agent bots?'
      );
    });

    it('escapes markup when diffing plain text', () => {
      const result = renderInlineDiff('a', 'a <b>');
      expect(result).toContain('&lt;b&gt;');
      expect(result).not.toContain('<b>');
    });

    it('treats a cleared empty string as a full deletion', () => {
      const result = renderInlineDiff('gone', '');
      expect(result).toContain('<del');
      expect(result).toContain('gone');
    });
  });

  describe('buildDiffBlocks', () => {
    it('passes an unchanged block through as equal', () => {
      const blocks = buildDiffBlocks('same para', 'same para');
      expect(blocks).toEqual([{ type: 'equal', md: 'same para' }]);
    });

    it('marks an appended block as added', () => {
      const blocks = buildDiffBlocks('a', 'a\n\nb');
      expect(blocks).toContainEqual({ type: 'equal', md: 'a' });
      expect(blocks).toContainEqual({ type: 'added', md: 'b' });
    });

    it('marks a deleted block as removed', () => {
      const blocks = buildDiffBlocks('a\n\nb', 'a');
      expect(blocks).toContainEqual({ type: 'removed', md: 'b' });
    });

    it('emits the old block then the new block for a reworded section', () => {
      const blocks = buildDiffBlocks('hello world', 'hello there');
      expect(blocks).toEqual([
        { type: 'removed', md: 'hello world' },
        { type: 'added', md: 'hello there' },
      ]);
    });

    it('keeps a fenced code block whole when it contains blank lines', () => {
      const code = '```\nline one\n\nline two\n```';
      const blocks = buildDiffBlocks(code, code);
      expect(blocks).toEqual([{ type: 'equal', md: code }]);
    });

    it('diffs an edited code block as one whole removed + added block', () => {
      const live = '```\ncode line\n```';
      const draft = '```\ncode line\n\nsd\n```';
      const blocks = buildDiffBlocks(live, draft);
      expect(blocks).toContainEqual({ type: 'removed', md: live });
      expect(blocks).toContainEqual({ type: 'added', md: draft });
    });

    it('surfaces whitespace edits that change the rendered output', () => {
      expect(
        buildDiffBlocks('```\nx\n```', '```\n  x\n```').some(
          block => block.type !== 'equal'
        )
      ).toBe(true);
      expect(
        buildDiffBlocks('line one\nline two', 'line one  \nline two').some(
          block => block.type !== 'equal'
        )
      ).toBe(true);
    });

    it('surfaces an indented code block turning into a paragraph', () => {
      const blocks = buildDiffBlocks(
        '    curl example.com',
        'curl example.com'
      );
      expect(blocks).toContainEqual({
        type: 'removed',
        md: '    curl example.com',
      });
      expect(blocks).toContainEqual({ type: 'added', md: 'curl example.com' });
    });

    it('keeps spacing the renderer ignores as equal', () => {
      const blocks = buildDiffBlocks('a\nb', 'a \nb');
      expect(blocks.every(block => block.type === 'equal')).toBe(true);
    });

    it('keeps a loose list with item descriptions as one block', () => {
      const list =
        '1. **One**\n\n   First item.\n\n2. **Two**\n\n   Second item.';
      const blocks = buildDiffBlocks(list, list);
      expect(blocks).toEqual([{ type: 'equal', md: list }]);
    });
  });

  describe('rendersIdentically', () => {
    it('ignores blank-line / empty-paragraph differences', () => {
      expect(rendersIdentically('a\n\nb', 'a\n\n\nb')).toBe(true);
      expect(rendersIdentically('hello', 'hello\n\n')).toBe(true);
    });

    it('counts code-block indentation changes', () => {
      expect(rendersIdentically('```\n  x\n```', '```\nx\n```')).toBe(false);
    });

    it('counts smart vs straight quotes (no typographer)', () => {
      expect(rendersIdentically('"hi"', '“hi”')).toBe(false);
    });

    it('counts real text changes', () => {
      expect(rendersIdentically('hello world', 'hello there')).toBe(false);
    });

    it('treats nullish input as empty', () => {
      expect(rendersIdentically(null, '')).toBe(true);
      expect(rendersIdentically(undefined, 'x')).toBe(false);
    });
  });

  describe('hasPendingChanges', () => {
    it('is true when a draft title or content is staged', () => {
      expect(hasPendingChanges({ draftContent: 'edit' })).toBe(true);
      expect(hasPendingChanges({ draftTitle: 'edit' })).toBe(true);
    });

    it('treats a cleared empty-string draft as a pending change', () => {
      expect(hasPendingChanges({ draftTitle: '' })).toBe(true);
    });

    it('is false with no draft columns', () => {
      expect(hasPendingChanges({ title: 'live' })).toBe(false);
      expect(hasPendingChanges({})).toBe(false);
      expect(hasPendingChanges(null)).toBe(false);
    });
  });
});
