import { readFileSync, readdirSync, statSync } from 'fs';
import path from 'path';

// The same question was open in three composers at once, and each of them had answered it with
// its own inline `filter(file => file.size > 0)`. Fixing three call sites without a fence just
// resets the clock: the fourth composer copies the line from one of the first three, and the
// silent drop is back with nobody to notice.
//
// So the rule is that the size test lives in one place. A new entry point either uses the
// helper, which decides whether to explain the refusal, or this fails and asks why.
const ROOT = path.resolve(__dirname, '../../..');
// `isFileEmpty` in shared/helpers/FileHelper.js is the one predicate, and dashboard/helper/
// pastedFiles.js is the one place that decides what to do about a file it refuses. Everything
// else asks them.
const HELPER = path.join(ROOT, 'shared/helpers/FileHelper.js');
const EXTENSIONS = ['.js', '.vue'];
const SKIP_DIRS = new Set(['node_modules', 'specs', 'i18n']);

// `size` is a common enough name that a bare mention would flag unrelated code, so the fence
// matches the shape that drops files: a size comparison inside a filter or a guard over
// something named like a file.
const SIZE_FILTER =
  /\b(?:file|f|attachment)\s*(?:&&\s*\1\s*)?\.size\s*(?:>|>=|===|!==|==)\s*0/;

const walk = dir =>
  readdirSync(dir).flatMap(entry => {
    const full = path.join(dir, entry);
    if (statSync(full).isDirectory()) {
      return SKIP_DIRS.has(entry) ? [] : walk(full);
    }
    return EXTENSIONS.includes(path.extname(entry)) ? [full] : [];
  });

describe('the zero-byte test lives in one place', () => {
  it('has no other file deciding on its own what an empty file means', () => {
    const offenders = walk(ROOT)
      .filter(file => file !== HELPER)
      .filter(file => SIZE_FILTER.test(readFileSync(file, 'utf8')))
      .map(file => path.relative(ROOT, file));

    expect(offenders).toEqual([]);
  });

  it('still finds the predicate itself, so the fence is not matching nothing', () => {
    expect(SIZE_FILTER.test(readFileSync(HELPER, 'utf8'))).toBe(true);
  });

  // Three of the four sites that had the inline filter were `.vue` files, so a sweep that only
  // reads `.js` would pass while saying nothing about the composers this issue is actually
  // about. The list is checked rather than the extensions constant: what matters is that the
  // walk reaches them.
  it('sweeps the components, not only the plain modules', () => {
    const swept = walk(ROOT);

    expect(swept.some(file => file.endsWith('.vue'))).toBe(true);
    expect(swept).toContain(
      path.join(ROOT, 'dashboard/components/widgets/conversation/ReplyBox.vue')
    );
    expect(swept).toContain(
      path.join(
        ROOT,
        'dashboard/routes/dashboard/internalChat/MessageEditor.vue'
      )
    );
    expect(swept).toContain(
      path.join(
        ROOT,
        'dashboard/components-next/NewConversation/components/ActionButtons.vue'
      )
    );
  });
});
