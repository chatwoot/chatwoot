import { readFileSync, readdirSync, statSync } from 'fs';
import path from 'path';

// The prop that draws the spinner is `isLoading`. A call site writing `loading` instead gets no
// error from anywhere: the name is not declared and not in EXCLUDED_ATTRS, so it falls through
// `useAttrs` onto the `<button>` element, where the browser ignores it. Two call sites had made
// that mistake, and 420 other files import the same component, so fixing two lines without a
// fence just resets the clock until somebody copies a line from the wrong one of them.
//
// The risk in a fence like this is not the false positive, it is the empty green: if the
// resolution breaks, it finds nothing and passes forever. So every sweep here asserts a positive
// floor in the same example that looks for the defect.
const JS_ROOT = path.resolve(__dirname, '../../../../');
const BUTTON = path.join(
  JS_ROOT,
  'dashboard/components-next/button/Button.vue'
);

// Kept in step with `vite.shared.ts` by hand on purpose: reading the TS config from a spec would
// mean parsing it, and getting an alias wrong makes the fence quieter rather than louder, which
// is what the floors below are for.
const ALIASES = {
  next: path.join(JS_ROOT, 'dashboard/components-next'),
  dashboard: path.join(JS_ROOT, 'dashboard'),
  components: path.join(JS_ROOT, 'dashboard/components'),
  shared: path.join(JS_ROOT, 'shared'),
  v3: path.join(JS_ROOT, 'v3'),
  widget: path.join(JS_ROOT, 'widget'),
  survey: path.join(JS_ROOT, 'survey'),
  helpers: path.join(JS_ROOT, 'shared/helpers'),
  assets: path.join(JS_ROOT, 'dashboard/assets'),
};

const SKIP_DIRS = new Set(['node_modules']);

const walk = dir =>
  readdirSync(dir).flatMap(entry => {
    const full = path.join(dir, entry);
    if (statSync(full).isDirectory()) {
      return SKIP_DIRS.has(entry) ? [] : walk(full);
    }
    return full.endsWith('.vue') ? [full] : [];
  });

// The specifier is resolved to an absolute path rather than matched as a substring. `Button` is
// not an exclusive name for this component (`v3/components/GoogleOauth/Button.vue` is another
// one), and a substring filter on `components-next/button` would miss both the `next/...`
// spelling, which is where one of the two real defects lived, and `./Button.vue`, which does not
// carry `button/` at all.
const resolveSpecifier = (specifier, fromFile) => {
  if (specifier.startsWith('.')) {
    return path.resolve(path.dirname(fromFile), specifier);
  }
  const [head, ...rest] = specifier.split('/');
  return ALIASES[head] ? path.join(ALIASES[head], ...rest) : null;
};

const IMPORT =
  /import\s+(\{[^}]*\}|[A-Za-z_$][\w$]*)\s+from\s+['"]([^'"]+)['"]/g;

// The local name comes from the import, never from a list. A sixth name is free to appear, and
// the list of three names this work arrived with was already missing two.
const localNames = (source, file) =>
  [...source.matchAll(IMPORT)]
    .filter(([, , specifier]) => resolveSpecifier(specifier, file) === BUTTON)
    .flatMap(([, imported]) => {
      if (!imported.startsWith('{')) return [imported];

      return imported
        .slice(1, -1)
        .split(',')
        .map(part => part.trim())
        .filter(Boolean)
        .map(part => part.split(/\s+as\s+/).map(bit => bit.trim()))
        .filter(([base]) => base === 'default' || base === 'Button')
        .map(([base, alias]) => alias || base);
    })
    .reduce((names, name) => names.add(name), new Set());

// Both real call sites spread their opening tag over several lines with `:loading` on a line of
// its own, so the unit is the whole opening tag, read to the first `>` outside quotes. Reading to
// the end of the line would miss them.
//
// Quotes do two jobs here, and getting only the first one right is how this fence rejected correct
// code on its first draft. They decide where the tag ends, so a `>` inside a value does not cut it
// short; and they decide what may be matched, because a value is data. `:label="keep loading the
// report"` is a correct tag, and matching over the raw text turns every translated label that
// happens to contain the word into a rejection. So the matcher runs against a skeleton where every
// quoted value is blanked out and only attribute names survive.
const readTag = (source, start) => {
  let index = start;
  let quote = null;
  let skeleton = '';
  while (index < source.length) {
    const char = source[index];
    if (quote) {
      if (char === quote) quote = null;
    } else if (char === '"' || char === "'") {
      quote = char;
    } else if (char === '>') {
      break;
    } else {
      skeleton += char;
    }
    index += 1;
  }
  return { skeleton, end: index };
};

const openingTags = (source, name) =>
  [...source.matchAll(new RegExp(`<${name}(?=[\\s/>])`, 'g'))].map(match => {
    const { skeleton, end } = readTag(source, match.index + match[0].length);

    return {
      text: `${match[0]}${skeleton}>`,
      raw: source.slice(match.index, end + 1),
      line: source.slice(0, match.index).split('\n').length,
    };
  });

// `loading`, `:loading`, `v-bind:loading`, a bare `loading`, and any modifier (`:loading.attr`).
// Anchored on whitespace so `is-loading` and `isLoading` are not swept up by the suffix.
const WRONG = /(?:^|\s)(?::|v-bind:)?loading(?:\.[\w.]+)?(?=[\s=/>])/;
const RIGHT =
  /(?:^|\s)(?::|v-bind:)?(?:is-loading|isLoading)(?:\.[\w.]+)?(?=[\s=/>])/;
// Any spread, not only one of `attrs`. A plain object works just as well: `v-bind="buttonProps"`
// with `{ loading: true }` puts the inert attribute on the element exactly like the two call sites
// this PR fixes, and no sweep of the source can see inside the object.
//
// Matched by attribute NAME, on the skeleton, for the same reason the wrong-prop matcher is: the
// value is data. Reading the raw tag to find the value turns a correct tag carrying the string
// `v-bind="..."` inside a label or a doc link into a rejection, which is the false positive on
// the other side of the one this pattern was widened to fix.
const SPREAD = /(?:^|\s)v-bind\s*=/;

// The detector takes a source string and the path it would live at, so the same code that sweeps
// the tree can be pointed at a synthetic file. That is not a convenience: on a clean tree there is
// no wrong call site left, so a sweep of the tree alone never exercises the matcher at all, and a
// matcher that stopped matching would stay green forever. The examples below plant the defect
// instead of hoping to find it.
const scanSource = (source, file) => {
  const names = localNames(source, file);
  const tags = [...names].flatMap(name =>
    openingTags(source, name).map(tag => ({
      ...tag,
      where: `${path.relative(JS_ROOT, file)}:${tag.line}`,
    }))
  );

  return {
    resolves: names.size > 0,
    names,
    wrong: tags.filter(tag => WRONG.test(tag.text)).map(tag => tag.where),
    right: tags.filter(tag => RIGHT.test(tag.text)).map(tag => tag.where),
    spreads: tags.filter(tag => SPREAD.test(tag.text)).map(tag => tag.where),
  };
};

const survey = () => {
  const files = walk(JS_ROOT);
  const found = files
    .map(file => ({ file, ...scanSource(readFileSync(file, 'utf8'), file) }))
    .filter(entry => entry.resolves);

  return {
    files,
    resolved: found.map(entry => entry.file),
    wrong: found.flatMap(entry => entry.wrong),
    right: found.reduce((total, entry) => total + entry.right.length, 0),
    spreads: found.flatMap(entry => entry.spreads),
  };
};

describe('the spinner prop of the next Button has one spelling', () => {
  it('has no call site passing `loading`, and reached enough of the tree to mean it', () => {
    const { resolved, wrong, right } = survey();

    // The floors are the whole point of this example, and they are asserted here rather than in
    // one of their own: a sweep that reports zero offenders because it resolved zero files is
    // indistinguishable from a sweep that found nothing wrong. Measured here: 417 `.vue` files and
    // 171 correct bindings. The floors sit well below that so a legitimate refactor does not trip
    // them, and well above zero so moving Button.vue, renaming an alias in vite.shared.ts or
    // breaking the resolver turns this red instead of quietly green.
    //
    // A census that counts imports rather than templates gets 422, and the five extra are
    // `.spec.js` files that import the component to mount it in a test. They are not call sites,
    // and only a `.vue` file carries a template, so the sweep stays on `.vue`. What that leaves
    // uncovered is a render function building the tag in JavaScript (`h(Button, { loading })`),
    // which this tag-shaped regex could not read anyway.
    expect(resolved.length).toBeGreaterThan(300);
    expect(right).toBeGreaterThan(100);

    expect(wrong).toEqual([]);
  });

  it('finds the component through every specifier spelling in the tree', () => {
    const { resolved } = survey();
    const spellings = resolved
      .flatMap(file =>
        [...readFileSync(file, 'utf8').matchAll(IMPORT)]
          .filter(match => resolveSpecifier(match[2], file) === BUTTON)
          .map(match => match[2])
      )
      .reduce((names, name) => names.add(name), new Set());

    // Five spellings exist today, including two that a substring filter on `button/Button.vue`
    // cannot see. The assertion is on the resolver reaching all of them, not on the count.
    expect(spellings).toContain('dashboard/components-next/button/Button.vue');
    expect(spellings).toContain('next/button/Button.vue');
    expect([...spellings].some(name => name.startsWith('.'))).toBe(true);
    expect(spellings.size).toBeGreaterThanOrEqual(3);
  });

  it('does not count a tag of some other component, including another Button.vue', () => {
    const other = path.join(JS_ROOT, 'v3/components/GoogleOauth/Button.vue');
    const source = readFileSync(other, 'utf8');

    expect(resolveSpecifier('./Button.vue', other)).not.toBe(BUTTON);
    expect(localNames(source, other).size).toBe(0);
  });

  // A `loading` arriving at the element from inside a spread, or through a dynamic attribute
  // name, is invisible to any source sweep and stays a hole after this fix. One tag spreads
  // today and neither of its callers passes `loading`, so nothing leaks; a second one has to show
  // up in review rather than land quietly.
  it('has no more attribute spreads on that tag than the one already reviewed', () => {
    const { spreads } = survey();

    // Compared by file, not by line: an import or a comment added above that tag shifts the line
    // and would turn this red while the spread and the loading behaviour are untouched, and a
    // fence that goes red for an unrelated edit is one that gets switched off. The count still
    // bites, because a second spread anywhere, including a second one in this same file, adds an
    // entry: the comparison maps, it does not deduplicate.
    //
    // The lines are carried in the failure message rather than in the compared value, because the
    // compared value is exactly where they had to stop mattering. Without that, a second spread in
    // this same file prints the same name twice with no way to tell which tag is the new one,
    // which is the one case where locating it is what the reader needs.
    expect(
      spreads.map(where => where.replace(/:\d+$/, '')),
      `spreads found: ${spreads.join(', ')}`
    ).toEqual(['dashboard/components-next/Contacts/VoiceCallButton.vue']);
  });
});

// Everything above measures the tree. This measures the detector, by planting the defect in a
// synthetic file placed where a real call site would sit. Each example asserts a count, because
// "0 rejections" is a substring of "10 rejections" and a matcher that answered nothing would read
// as one that answered correctly.
describe('the sweep that finds it actually finds it', () => {
  const HOME = path.join(
    JS_ROOT,
    'dashboard/routes/dashboard/inventado/Plantado.vue'
  );

  const planted = (specifier, name, attribute) =>
    scanSource(
      [
        '<script setup>',
        `import ${name} from '${specifier}';`,
        '</script>',
        '',
        '<template>',
        `  <${name}`,
        '    sm',
        '    solid',
        `    ${attribute}`,
        '    :disabled="busy"',
        '  >',
        '    Register',
        `  </${name}>`,
        '</template>',
      ].join('\n'),
      HOME
    );

  // A novel local name on purpose: the list of names this work arrived with was already missing
  // two, so a sixth is free to appear and the fence must not be tied to today's vocabulary.
  const NAME = 'ButtonSeisPontoZero';

  // All five spellings resolve to the same component, and two of them a substring filter on
  // `button/Button.vue` cannot see.
  it.each([
    'dashboard/components-next/button/Button.vue',
    'next/button/Button.vue',
    '../../../../components-next/button/Button.vue',
    './Button.vue',
    './button/Button.vue',
  ])('catches it through the %s spelling', specifier => {
    const relative = specifier.startsWith('.')
      ? path.relative(
          path.dirname(HOME),
          path.join(JS_ROOT, 'dashboard/components-next/button/Button.vue')
        )
      : specifier;
    const found = planted(relative, NAME, ':loading="busy"');

    expect(found.resolves).toBe(true);
    expect(found.wrong).toHaveLength(1);
  });

  // The tag is multi-line in both real call sites, with the offending binding on a line of its
  // own, so a sweep that reads to the end of the line finds nothing.
  it.each([
    ':loading="busy"',
    'v-bind:loading="busy"',
    'loading="true"',
    'loading',
    ':loading.attr="busy"',
  ])('catches the %s form inside a multi-line tag', attribute => {
    const found = planted('next/button/Button.vue', NAME, attribute);

    expect(found.wrong).toHaveLength(1);
    expect(found.wrong[0]).toBe(
      'dashboard/routes/dashboard/inventado/Plantado.vue:6'
    );
  });

  it('names the file and the line it rejected, not just a count', () => {
    const found = planted('next/button/Button.vue', NAME, ':loading="busy"');

    expect(found.wrong[0]).toMatch(/Plantado\.vue:\d+$/);
  });

  // The word appears inside a quoted value here, which is what a translated label looks like.
  // Walking the tag without tracking quotes turns every such label into a rejection, and a fence
  // that rejects correct code gets switched off the first time it is inconvenient.
  it('does not reject a correct tag whose label contains the word', () => {
    const found = scanSource(
      [
        '<script setup>',
        `import ${NAME} from 'next/button/Button.vue';`,
        '</script>',
        '',
        '<template>',
        `  <${NAME}`,
        // Lower case, and with whitespace on both sides, so it is a string the matcher would
        // accept if it were not tracking quotes. `SETTINGS.LOADING_STRATEGY` would not do: the
        // matcher is case sensitive and wants a delimiter after the word, so an upper-case label
        // would pass even with the quote tracking removed, and the example would prove nothing.
        '    :label="t(\'keep loading the report\')"',
        '    :is-loading="busy"',
        '  />',
        '</template>',
      ].join('\n'),
      HOME
    );

    expect(found.wrong).toEqual([]);
    expect(found.right).toHaveLength(1);
  });

  // The other spellings of the right prop, none of which may be rejected.
  it.each([':is-loading="busy"', 'is-loading', ':isLoading="busy"'])(
    'accepts the %s spelling',
    attribute => {
      const found = planted('next/button/Button.vue', NAME, attribute);

      expect(found.wrong).toEqual([]);
      expect(found.right).toHaveLength(1);
    }
  );

  // Both guards below are against false positives, and the collisions they avoid are real in this
  // tree rather than hypothetical: `:loading-message`, `:loading-placeholder` and `loading-more`
  // all exist as attributes, and five files import this Button as `Button` while also using
  // `<ButtonGroup>`. None of those carries a `loading` today, which is precisely why they need a
  // planted example: without one, removing either guard changes nothing and the fence would drift
  // into rejecting correct code the first time one of them does.
  // The only spread in the tree today binds `attrs`, so narrowing the pattern back to that one
  // name changes no count and would go unnoticed. A plain object is the cheaper way to reproduce
  // the defect: `v-bind="buttonProps"` with `{ loading: true }` puts the inert attribute on the
  // element exactly like the two call sites this PR fixes.
  it('counts a spread of a plain object, not only one of attrs', () => {
    const found = planted(
      'next/button/Button.vue',
      NAME,
      'v-bind="buttonProps"'
    );

    expect(found.spreads).toHaveLength(1);
    expect(found.wrong).toEqual([]);
  });

  // The mirror of the example above. A value can legitimately contain the text `v-bind="..."`, in a
  // label or a link to the docs, and counting spreads off the raw tag turns that into a rejection.
  it('does not count a spread that is only mentioned inside a value', () => {
    const found = scanSource(
      [
        '<script setup>',
        `import ${NAME} from 'next/button/Button.vue';`,
        '</script>',
        '',
        '<template>',
        `  <${NAME}`,
        '    title=\'see v-bind="something" in the docs\'',
        '    :is-loading="busy"',
        '  />',
        '</template>',
      ].join('\n'),
      HOME
    );

    expect(found.spreads).toEqual([]);
    expect(found.wrong).toEqual([]);
    expect(found.right).toHaveLength(1);
  });

  it('does not treat a longer attribute name as the prop', () => {
    const found = planted(
      'next/button/Button.vue',
      NAME,
      ':loading-message="t(\'CHAT.WAITING\')"'
    );

    expect(found.wrong).toEqual([]);
  });

  it('does not match a different tag whose name starts with the same word', () => {
    const found = scanSource(
      [
        '<script setup>',
        "import Button from 'next/button/Button.vue';",
        "import ButtonGroup from 'next/buttonGroup/ButtonGroup.vue';",
        '</script>',
        '',
        '<template>',
        '  <ButtonGroup :loading="busy" />',
        '  <Button :is-loading="busy" />',
        '</template>',
      ].join('\n'),
      HOME
    );

    expect(found.wrong).toEqual([]);
    expect(found.right).toHaveLength(1);
  });

  it('ignores a `loading` on a tag that is not this component', () => {
    const found = scanSource(
      [
        '<script setup>',
        `import ${NAME} from 'next/button/Button.vue';`,
        '</script>',
        '',
        '<template>',
        '  <img loading="lazy" src="x" />',
        '  <SomeOtherButton :loading="busy" />',
        `  <${NAME} :is-loading="busy" />`,
        '</template>',
      ].join('\n'),
      HOME
    );

    expect(found.wrong).toEqual([]);
    expect(found.right).toHaveLength(1);
  });
});
