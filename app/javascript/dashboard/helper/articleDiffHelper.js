// Powers the "unpublished changes" preview: marks what changed between the live
// article and the draft — word by word in the title, block by block in the body.

import MarkdownIt from 'markdown-it';

// Matches the public renderer (CommonMark, no typographer). True when two
// markdown strings render the same — so blank-line/spacing-only edits don't count,
// but real changes (code indentation, smart quotes, width markers) do.
const commonmark = MarkdownIt('commonmark');
export const rendersIdentically = (a, b) =>
  commonmark.render(a ?? '') === commonmark.render(b ?? '');

const INS_CLASS = '!bg-n-teal-5 !text-n-teal-12 !no-underline rounded px-0.5';
const DEL_CLASS = '!bg-n-ruby-5 !text-n-ruby-12 !line-through rounded px-0.5';

// Detailed compare gets slow on huge texts; past this, show all old as removed
// and all new as added.
const MAX_DIFF_TOKENS = 2000;

const tokenizeWords = value => (value || '').match(/\S+/g) || [];

const escapeHtml = value =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// Compares two lists in order and reports what's the same (`equal`), removed
// (`del`) or added (`ins`), keeping as much unchanged as possible. `keyOf` says
// how to compare items (title passes words, body passes blocks).
const diffSequence = (a, b, keyOf = item => item) => {
  const n = a.length;
  const m = b.length;
  if (n > MAX_DIFF_TOKENS || m > MAX_DIFF_TOKENS) {
    return [
      ...a.map(item => ({ type: 'del', item })),
      ...b.map(item => ({ type: 'ins', item })),
    ];
  }

  const dp = Array.from({ length: n + 1 }, () => new Array(m + 1).fill(0));
  for (let i = n - 1; i >= 0; i -= 1) {
    for (let j = m - 1; j >= 0; j -= 1) {
      dp[i][j] =
        keyOf(a[i]) === keyOf(b[j])
          ? dp[i + 1][j + 1] + 1
          : Math.max(dp[i + 1][j], dp[i][j + 1]);
    }
  }

  const ops = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (keyOf(a[i]) === keyOf(b[j])) {
      ops.push({ type: 'equal', item: a[i] });
      i += 1;
      j += 1;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      ops.push({ type: 'del', item: a[i] });
      i += 1;
    } else {
      ops.push({ type: 'ins', item: b[j] });
      j += 1;
    }
  }
  while (i < n) {
    ops.push({ type: 'del', item: a[i] });
    i += 1;
  }
  while (j < m) {
    ops.push({ type: 'ins', item: b[j] });
    j += 1;
  }
  return ops;
};

const wrapDiff = {
  ins: text => `<ins class="${INS_CLASS}">${text}</ins>`,
  del: text => `<del class="${DEL_CLASS}">${text}</del>`,
};

// Builds the highlighted title. Compares whole words (not single spaces) so
// repeated words/spaces don't make the highlights jump around, then rejoins
// with single spaces — a run of added/removed words shares one <ins>/<del> tag.
export const renderInlineDiff = (oldValue, newValue) => {
  const ops = diffSequence(tokenizeWords(oldValue), tokenizeWords(newValue));

  const segments = [];
  let run = [];
  let runType = null;
  const flushRun = () => {
    if (!run.length) return;
    const text = run.map(escapeHtml).join(' ');
    segments.push(wrapDiff[runType] ? wrapDiff[runType](text) : text);
    run = [];
  };

  ops.forEach(({ type, item }) => {
    if (type !== runType) flushRun();
    runType = type;
    run.push(item);
  });
  flushRun();

  return segments.join(' ');
};

// A fenced code block opener: ``` or ~~~, indented up to 3 spaces (CommonMark).
const FENCE_RE = /^ {0,3}(```|~~~)/;
// A list item marker: -, *, + or "1." / "1)", indented up to 3 spaces.
const LIST_ITEM_RE = /^ {0,3}(?:[-*+]|\d{1,9}[.)])(?:\s|$)/;

// Split on blank lines so each paragraph, heading or list compares as one piece.
// Blank lines inside a fenced code block, or between items of the same list, are
// content — splitting there would tear a code block or list apart and render it
// with broken structure (orphaned <li>/<p>), so we keep those together.
const splitBlocks = text => {
  const lines = (text || '').split('\n');
  const blocks = [];
  let buffer = [];
  let fence = null;
  let inList = false;

  const flush = () => {
    const block = buffer.join('\n');
    if (block.trim()) blocks.push(block);
    buffer = [];
    inList = false;
  };

  lines.forEach((line, index) => {
    const marker = line.match(FENCE_RE)?.[1];
    if (marker && !fence) fence = marker;
    else if (fence && line.trimStart().startsWith(fence)) fence = null;

    if (fence) {
      buffer.push(line);
      return;
    }

    if (LIST_ITEM_RE.test(line)) inList = true;

    if (line.trim() !== '') {
      buffer.push(line);
      return;
    }

    // Blank line: keep it when the current list continues on the next non-blank
    // line (another item or an indented continuation); otherwise end the block.
    const next = lines.slice(index + 1).find(other => other.trim() !== '');
    if (inList && next && (LIST_ITEM_RE.test(next) || /^\s/.test(next))) {
      buffer.push(line);
    } else {
      flush();
    }
  });

  flush();
  return blocks;
};

const BLOCK_TYPE = { equal: 'equal', del: 'removed', ins: 'added' };

// Diffs the body block by block. Blocks match when they render to the same HTML
// (the check staging uses), so only edits that change the page show as a diff.
export const buildDiffBlocks = (oldText, newText) => {
  const toBlocks = text =>
    splitBlocks(text).map(md => ({ md, key: commonmark.render(md) }));
  const ops = diffSequence(toBlocks(oldText), toBlocks(newText), b => b.key);
  return ops.map(op => ({ type: BLOCK_TYPE[op.type], md: op.item.md }));
};

export const hasPendingChanges = article =>
  article?.draftTitle != null || article?.draftContent != null;
