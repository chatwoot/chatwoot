// Source: https://www.w3.org/TR/html-aam-1.0/#element-mapping-table
// Source: https://www.w3.org/TR/html-aria/
import getElementsByContentType from './get-elements-by-content-type';
import getGlobalAriaAttrs from './get-global-aria-attrs';
import arialabelledbyText from '../aria/arialabelledby-text';
import arialabelText from '../aria/arialabel-text';
import idrefs from '../dom/idrefs';
import isColumnHeader from '../table/is-column-header';
import isRowHeader from '../table/is-row-header';
import sanitize from '../text/sanitize';
import isFocusable from '../dom/is-focusable';
import { closest } from '../../core/utils';
import getExplicitRole from '../aria/get-explicit-role';

const sectioningElementSelector =
  getElementsByContentType('sectioning')
    .map(nodeName => `${nodeName}:not([role])`)
    .join(', ') +
  ' , main:not([role]), [role=article], [role=complementary], [role=main], [role=navigation], [role=region]';

// sectioning elements only have an accessible name if the
// aria-label, aria-labelledby, or title attribute has valid
// content.
// can't go through the normal accessible name computation
// as it leads into an infinite loop of asking for the role
// of the element while the implicit role needs the name.
// Source: https://www.w3.org/TR/html-aam-1.0/#section-and-grouping-element-accessible-name-computation
//
// form elements also follow this same pattern although not
// specifically called out in the spec like section elements
// (per Scott O'Hara)
// Source: https://web-a11y.slack.com/archives/C042TSFGN/p1590607895241100?thread_ts=1590602189.217800&cid=C042TSFGN
function hasAccessibleName(vNode) {
  // testing for when browsers give a <section> a region role:
  // chrome - always a region role
  // firefox - if non-empty aria-labelledby, aria-label, or title
  // safari - if non-empty aria-lablledby or aria-label
  //
  // we will go with safaris implantation as it is the least common
  // denominator
  const ariaLabelledby = sanitize(arialabelledbyText(vNode));
  const ariaLabel = sanitize(arialabelText(vNode));

  return !!(ariaLabelledby || ariaLabel);
}

const implicitHtmlRoles = {
  a: vNode => {
    return vNode.hasAttr('href') ? 'link' : null;
  },
  area: vNode => {
    return vNode.hasAttr('href') ? 'link' : null;
  },
  article: 'article',
  aside: 'complementary',
  body: 'document',
  button: 'button',
  datalist: 'listbox',
  dd: 'definition',
  dfn: 'term',
  details: 'group',
  dialog: 'dialog',
  dt: 'term',
  fieldset: 'group',
  figure: 'figure',
  footer: vNode => {
    const sectioningElement = closest(vNode, sectioningElementSelector);

    return !sectioningElement ? 'contentinfo' : null;
  },
  form: vNode => {
    return hasAccessibleName(vNode) ? 'form' : null;
  },
  h1: 'heading',
  h2: 'heading',
  h3: 'heading',
  h4: 'heading',
  h5: 'heading',
  h6: 'heading',
  header: vNode => {
    const sectioningElement = closest(vNode, sectioningElementSelector);

    return !sectioningElement ? 'banner' : null;
  },
  hr: 'separator',
  img: vNode => {
    // an images role is considered implicitly presentation if the
    // alt attribute is empty. But that shouldn't be the case if it
    // has global aria attributes or is focusable, so we need to
    // override the role back to `img`
    // e.g. <img alt="" aria-label="foo"></img>
    const emptyAlt = vNode.hasAttr('alt') && !vNode.attr('alt');
    const hasGlobalAria = getGlobalAriaAttrs().find(attr =>
      vNode.hasAttr(attr)
    );

    return emptyAlt && !hasGlobalAria && !isFocusable(vNode)
      ? 'presentation'
      : 'img';
  },
  input: vNode => {
    // Source: https://www.w3.org/TR/html52/sec-forms.html#suggestions-source-element
    let suggestionsSourceElement;
    if (vNode.hasAttr('list')) {
      const listElement = idrefs(vNode.actualNode, 'list').filter(
        node => !!node
      )[0];
      suggestionsSourceElement =
        listElement && listElement.nodeName.toLowerCase() === 'datalist';
    }

    switch (vNode.props.type) {
      case 'button':
      case 'image':
      case 'reset':
      case 'submit':
        return 'button';
      case 'checkbox':
        return 'checkbox';
      case 'email':
      case 'tel':
      case 'text':
      case 'url':
      case '': // text is the default value
        return !suggestionsSourceElement ? 'textbox' : 'combobox';
      case 'number':
        return 'spinbutton';
      case 'radio':
        return 'radio';
      case 'range':
        return 'slider';
      case 'search':
        return !suggestionsSourceElement ? 'searchbox' : 'combobox';
    }
  },
  // Note: if an li (or some other elms) do not have a required
  // parent, Firefox ignores the implicit semantic role and treats
  // it as a generic text.
  li: 'listitem',
  main: 'main',
  math: 'math',
  menu: 'list',
  nav: 'navigation',
  ol: 'list',
  optgroup: 'group',
  option: 'option',
  output: 'status',
  progress: 'progressbar',
  section: vNode => {
    return hasAccessibleName(vNode) ? 'region' : null;
  },
  select: vNode => {
    return vNode.hasAttr('multiple') || parseInt(vNode.attr('size')) > 1
      ? 'listbox'
      : 'combobox';
  },
  summary: 'button',
  table: 'table',
  tbody: 'rowgroup',
  td: vNode => {
    const table = closest(vNode, 'table');
    const role = getExplicitRole(table);

    return ['grid', 'treegrid'].includes(role) ? 'gridcell' : 'cell';
  },
  textarea: 'textbox',
  tfoot: 'rowgroup',
  th: vNode => {
    if (isColumnHeader(vNode.actualNode)) {
      return 'columnheader';
    }
    if (isRowHeader(vNode.actualNode)) {
      return 'rowheader';
    }
  },
  thead: 'rowgroup',
  tr: 'row',
  ul: 'list'
};

export default implicitHtmlRoles;
