// aria
import abstractroleEvaluate from '../../checks/aria/abstractrole-evaluate';
import ariaAllowedAttrEvaluate from '../../checks/aria/aria-allowed-attr-evaluate';
import ariaAllowedRoledEvaluate from '../../checks/aria/aria-allowed-role-evaluate';
import ariaErrormessageEvaluate from '../../checks/aria/aria-errormessage-evaluate';
import ariaHiddenBodyEvaluate from '../../checks/aria/aria-hidden-body-evaluate';
import ariaProhibitedAttrEvaluate from '../../checks/aria/aria-prohibited-attr-evaluate';
import ariaRequiredAttrEvaluate from '../../checks/aria/aria-required-attr-evaluate';
import ariaRequiredChildrenEvaluate from '../../checks/aria/aria-required-children-evaluate';
import ariaRequiredParentEvaluate from '../../checks/aria/aria-required-parent-evaluate';
import ariaRoledescriptionEvaluate from '../../checks/aria/aria-roledescription-evaluate';
import ariaUnsupportedAttrEvaluate from '../../checks/aria/aria-unsupported-attr-evaluate';
import ariaValidAttrEvaluate from '../../checks/aria/aria-valid-attr-evaluate';
import ariaValidAttrValueEvaluate from '../../checks/aria/aria-valid-attr-value-evaluate';
import fallbackroleEvaluate from '../../checks/aria/fallbackrole-evaluate';
import hasGlobalAriaAttributeEvaluate from '../../checks/aria/has-global-aria-attribute-evaluate';
import hasWidgetRoleEvaluate from '../../checks/aria/has-widget-role-evaluate';
import invalidroleEvaluate from '../../checks/aria/invalidrole-evaluate';
import isElementFocusableEvaluate from '../../checks/aria/is-element-focusable-evaluate';
import noImplicitExplicitLabelEvaluate from '../../checks/aria/no-implicit-explicit-label-evaluate';
import unsupportedroleEvaluate from '../../checks/aria/unsupportedrole-evaluate';
import validScrollableSemanticsEvaluate from '../../checks/aria/valid-scrollable-semantics-evaluate';

// tables
import captionFakedEvaluate from '../../checks/tables/caption-faked-evaluate';
import html5ScopeEvaluate from '../../checks/tables/html5-scope-evaluate';
import sameCaptionSummaryEvaluate from '../../checks/tables/same-caption-summary-evaluate';
import scopeValueEvaluate from '../../checks/tables/scope-value-evaluate';
import tdHasHeaderEvaluate from '../../checks/tables/td-has-header-evaluate';
import tdHeadersAttrEvaluate from '../../checks/tables/td-headers-attr-evaluate';
import thHasDataCellsEvaluate from '../../checks/tables/th-has-data-cells-evaluate';

// visibility
import hiddenContentEvaluate from '../../checks/visibility/hidden-content-evaluate';

// color
import colorContrastEvaluate from '../../checks/color/color-contrast-evaluate';
import linkInTextBlockEvaluate from '../../checks/color/link-in-text-block-evaluate';

// forms
import autocompleteAppropriateEvaluate from '../../checks/forms/autocomplete-appropriate-evaluate';
import autocompleteValidEvaluate from '../../checks/forms/autocomplete-valid-evaluate';

// generic
import attrNonSpaceContentEvaluate from '../../checks/generic/attr-non-space-content-evaluate';
import hasDescendantAfter from '../../checks/generic/has-descendant-after';
import hasDescendantEvaluate from '../../checks/generic/has-descendant-evaluate';
import hasTextContentEvaluate from '../../checks/generic/has-text-content-evaluate';
import matchesDefinitionEvaluate from '../../checks/generic/matches-definition-evaluate';
import pageNoDuplicateAfter from '../../checks/generic/page-no-duplicate-after';
import pageNoDuplicateEvaluate from '../../checks/generic/page-no-duplicate-evaluate';

// navigation
import headingOrderAfter from '../../checks/navigation/heading-order-after';
import headingOrderEvaluate from '../../checks/navigation/heading-order-evaluate';
import identicalLinksSamePurposeAfter from '../../checks/navigation/identical-links-same-purpose-after';
import identicalLinksSamePurposeEvaluate from '../../checks/navigation/identical-links-same-purpose-evaluate';
import internalLinkPresentEvaluate from '../../checks/navigation/internal-link-present-evaluate';
import metaRefreshEvaluate from '../../checks/navigation/meta-refresh-evaluate';
import pAsHeadingEvaluate from '../../checks/navigation/p-as-heading-evaluate';
import regionEvaluate from '../../checks/navigation/region-evaluate';
import skipLinkEvaluate from '../../checks/navigation/skip-link-evaluate';
import uniqueFrameTitleAfter from '../../checks/navigation/unique-frame-title-after';
import uniqueFrameTitleEvaluate from '../../checks/navigation/unique-frame-title-evaluate';

// shared
import ariaLabelEvaluate from '../../checks/shared/aria-label-evaluate';
import ariaLabelledbyEvaluate from '../../checks/shared/aria-labelledby-evaluate';
import avoidInlineSpacingEvaluate from '../../checks/shared/avoid-inline-spacing-evaluate';
import docHasTitleEvaluate from '../../checks/shared/doc-has-title-evaluate';
import existsEvaluate from '../../checks/shared/exists-evaluate';
import hasAltEvaluate from '../../checks/shared/has-alt-evaluate';
import isOnScreenEvaluate from '../../checks/shared/is-on-screen-evaluate';
import nonEmptyIfPresentEvaluate from '../../checks/shared/non-empty-if-present-evaluate';
import presentationalRoleEvaluate from '../../checks/shared/presentational-role-evaluate';
import svgNonEmptyTitleEvaluate from '../../checks/shared/svg-non-empty-title-evaluate';

// mobile
import cssOrientationLockEvaluate from '../../checks/mobile/css-orientation-lock-evaluate';
import metaViewportScaleEvaluate from '../../checks/mobile/meta-viewport-scale-evaluate';

// parsing
import duplicateIdAfter from '../../checks/parsing/duplicate-id-after';
import duplicateIdEvaluate from '../../checks/parsing/duplicate-id-evaluate';

// keyboard
import accesskeysAfter from '../../checks/keyboard/accesskeys-after';
import accesskeysEvaluate from '../../checks/keyboard/accesskeys-evaluate';
import focusableContentEvaluate from '../../checks/keyboard/focusable-content-evaluate';
import focusableDisabledEvaluate from '../../checks/keyboard/focusable-disabled-evaluate';
import focusableElementEvaluate from '../../checks/keyboard/focusable-element-evaluate';
import focusableModalOpenEvaluate from '../../checks/keyboard/focusable-modal-open-evaluate';
import focusableNoNameEvaluate from '../../checks/keyboard/focusable-no-name-evaluate';
import focusableNotTabbableEvaluate from '../../checks/keyboard/focusable-not-tabbable-evaluate';
import landmarkIsTopLevelEvaluate from '../../checks/keyboard/landmark-is-top-level-evaluate';
import noFocusableContentEvaluate from '../../checks/keyboard/no-focusable-content-evaluate';
import tabindexEvaluate from '../../checks/keyboard/tabindex-evaluate';

// label
import altSpaceValueEvaluate from '../../checks/label/alt-space-value-evaluate';
import duplicateImgLabelEvaluate from '../../checks/label/duplicate-img-label-evaluate';
import explicitEvaluate from '../../checks/label/explicit-evaluate';
import helpSameAsLabelEvaluate from '../../checks/label/help-same-as-label-evaluate';
import hiddenExplicitLabelEvaluate from '../../checks/label/hidden-explicit-label-evaluate';
import implicitEvaluate from '../../checks/label/implicit-evaluate';
import labelContentNameMismatchEvaluate from '../../checks/label/label-content-name-mismatch-evaluate';
import multipleLabelEvaluate from '../../checks/label/multiple-label-evaluate';
import titleOnlyEvaluate from '../../checks/label/title-only-evaluate';

// landmarks
import landmarkIsUniqueAfter from '../../checks/landmarks/landmark-is-unique-after';
import landmarkIsUniqueEvaluate from '../../checks/landmarks/landmark-is-unique-evaluate';

// language
import hasLangEvaluate from '../../checks/language/has-lang-evaluate';
import validLangEvaluate from '../../checks/language/valid-lang-evaluate';
import xmlLangMismatchEvaluate from '../../checks/language/xml-lang-mismatch-evaluate';

// lists
import dlitemEvaluate from '../../checks/lists/dlitem-evaluate';
import listitemEvaluate from '../../checks/lists/listitem-evaluate';
import onlyDlitemsEvaluate from '../../checks/lists/only-dlitems-evaluate';
import onlyListitemsEvaluate from '../../checks/lists/only-listitems-evaluate';
import structuredDlitemsEvaluate from '../../checks/lists/structured-dlitems-evaluate';

// media
import captionEvaluate from '../../checks/media/caption-evaluate';
import frameTestedEvaluate from '../../checks/media/frame-tested-evaluate';
import noAutoplayAudioEvaluate from '../../checks/media/no-autoplay-audio-evaluate';

// rule matches
import ariaAllowedAttrMatches from '../../rules/aria-allowed-attr-matches';
import ariaAllowedRoleMatches from '../../rules/aria-allowed-role-matches';
import ariaHasAttrMatches from '../../rules/aria-has-attr-matches';
import ariaHiddenFocusMatches from '../../rules/aria-hidden-focus-matches';
import ariaRequiredChildrenMatches from '../../rules/aria-required-children-matches';
import ariaRequiredParentMatches from '../../rules/aria-required-parent-matches';
import autocompleteMatches from '../../rules/autocomplete-matches';
import bypassMatches from '../../rules/bypass-matches';
import colorContrastMatches from '../../rules/color-contrast-matches';
import dataTableLargeMatches from '../../rules/data-table-large-matches';
import dataTableMatches from '../../rules/data-table-matches';
import duplicateIdActiveMatches from '../../rules/duplicate-id-active-matches';
import duplicateIdAriaMatches from '../../rules/duplicate-id-aria-matches';
import duplicateIdMiscMatches from '../../rules/duplicate-id-misc-matches';
import frameFocusableContentMatches from '../../rules/frame-focusable-content-matches';
import frameTitleHasTextMatches from '../../rules/frame-title-has-text-matches';
import headingMatches from '../../rules/heading-matches';
import htmlNamespaceMatches from '../../rules/html-namespace-matches';
import identicalLinksSamePurposeMatches from '../../rules/identical-links-same-purpose-matches';
import insertedIntoFocusOrderMatches from '../../rules/inserted-into-focus-order-matches';
import isInitiatorMatches from '../../rules/is-initiator-matches';
import labelContentNameMismatchMatches from '../../rules/label-content-name-mismatch-matches';
import labelMatches from '../../rules/label-matches';
import landmarkHasBodyContextMatches from '../../rules/landmark-has-body-context-matches';
import landmarkUniqueMatches from '../../rules/landmark-unique-matches';
import layoutTableMatches from '../../rules/layout-table-matches';
import linkInTextBlockMatches from '../../rules/link-in-text-block-matches';
import nestedInteractiveMatches from '../../rules/nested-interactive-matches';
import noAutoplayAudioMatches from '../../rules/no-autoplay-audio-matches';
import noEmptyRoleMatches from '../../rules/no-empty-role-matches';
import noExplicitNameRequiredMatches from '../../rules/no-explicit-name-required-matches';
import noNamingMethodMatches from '../../rules/no-naming-method-matches';
import noRoleMatches from '../../rules/no-role-matches';
import notHtmlMatches from '../../rules/not-html-matches';
import pAsHeadingMatches from '../../rules/p-as-heading-matches';
import scrollableRegionFocusableMatches from '../../rules/scrollable-region-focusable-matches';
import skipLinkMatches from '../../rules/skip-link-matches';
import svgNamespaceMatches from '../../rules/svg-namespace-matches';
import windowIsTopMatches from '../../rules/window-is-top-matches';
import xmlLangMismatchMatches from '../../rules/xml-lang-mismatch-matches';

const metadataFunctionMap = {
  // aria
  'abstractrole-evaluate': abstractroleEvaluate,
  'aria-allowed-attr-evaluate': ariaAllowedAttrEvaluate,
  'aria-allowed-role-evaluate': ariaAllowedRoledEvaluate,
  'aria-errormessage-evaluate': ariaErrormessageEvaluate,
  'aria-hidden-body-evaluate': ariaHiddenBodyEvaluate,
  'aria-prohibited-attr-evaluate': ariaProhibitedAttrEvaluate,
  'aria-required-attr-evaluate': ariaRequiredAttrEvaluate,
  'aria-required-children-evaluate': ariaRequiredChildrenEvaluate,
  'aria-required-parent-evaluate': ariaRequiredParentEvaluate,
  'aria-roledescription-evaluate': ariaRoledescriptionEvaluate,
  'aria-unsupported-attr-evaluate': ariaUnsupportedAttrEvaluate,
  'aria-valid-attr-evaluate': ariaValidAttrEvaluate,
  'aria-valid-attr-value-evaluate': ariaValidAttrValueEvaluate,
  'fallbackrole-evaluate': fallbackroleEvaluate,
  'has-global-aria-attribute-evaluate': hasGlobalAriaAttributeEvaluate,
  'has-widget-role-evaluate': hasWidgetRoleEvaluate,
  'invalidrole-evaluate': invalidroleEvaluate,
  'is-element-focusable-evaluate': isElementFocusableEvaluate,
  'no-implicit-explicit-label-evaluate': noImplicitExplicitLabelEvaluate,
  'unsupportedrole-evaluate': unsupportedroleEvaluate,
  'valid-scrollable-semantics-evaluate': validScrollableSemanticsEvaluate,

  // tables
  'caption-faked-evaluate': captionFakedEvaluate,
  'html5-scope-evaluate': html5ScopeEvaluate,
  'same-caption-summary-evaluate': sameCaptionSummaryEvaluate,
  'scope-value-evaluate': scopeValueEvaluate,
  'td-has-header-evaluate': tdHasHeaderEvaluate,
  'td-headers-attr-evaluate': tdHeadersAttrEvaluate,
  'th-has-data-cells-evaluate': thHasDataCellsEvaluate,

  // visibility
  'hidden-content-evaluate': hiddenContentEvaluate,

  // color
  'color-contrast-evaluate': colorContrastEvaluate,
  'link-in-text-block-evaluate': linkInTextBlockEvaluate,

  // forms
  'autocomplete-appropriate-evaluate': autocompleteAppropriateEvaluate,
  'autocomplete-valid-evaluate': autocompleteValidEvaluate,

  // generic
  'attr-non-space-content-evaluate': attrNonSpaceContentEvaluate,
  'has-descendant-after': hasDescendantAfter,
  'has-descendant-evaluate': hasDescendantEvaluate,
  'has-text-content-evaluate': hasTextContentEvaluate,
  'matches-definition-evaluate': matchesDefinitionEvaluate,
  'page-no-duplicate-after': pageNoDuplicateAfter,
  'page-no-duplicate-evaluate': pageNoDuplicateEvaluate,

  // navigation
  'heading-order-after': headingOrderAfter,
  'heading-order-evaluate': headingOrderEvaluate,
  'identical-links-same-purpose-after': identicalLinksSamePurposeAfter,
  'identical-links-same-purpose-evaluate': identicalLinksSamePurposeEvaluate,
  'internal-link-present-evaluate': internalLinkPresentEvaluate,
  'meta-refresh-evaluate': metaRefreshEvaluate,
  'p-as-heading-evaluate': pAsHeadingEvaluate,
  'region-evaluate': regionEvaluate,
  'skip-link-evaluate': skipLinkEvaluate,
  'unique-frame-title-after': uniqueFrameTitleAfter,
  'unique-frame-title-evaluate': uniqueFrameTitleEvaluate,

  // shared
  'aria-label-evaluate': ariaLabelEvaluate,
  'aria-labelledby-evaluate': ariaLabelledbyEvaluate,
  'avoid-inline-spacing-evaluate': avoidInlineSpacingEvaluate,
  'doc-has-title-evaluate': docHasTitleEvaluate,
  'exists-evaluate': existsEvaluate,
  'has-alt-evaluate': hasAltEvaluate,
  'is-on-screen-evaluate': isOnScreenEvaluate,
  'non-empty-if-present-evaluate': nonEmptyIfPresentEvaluate,
  'presentational-role-evaluate': presentationalRoleEvaluate,
  'svg-non-empty-title-evaluate': svgNonEmptyTitleEvaluate,

  // mobile
  'css-orientation-lock-evaluate': cssOrientationLockEvaluate,
  'meta-viewport-scale-evaluate': metaViewportScaleEvaluate,

  // parsing
  'duplicate-id-after': duplicateIdAfter,
  'duplicate-id-evaluate': duplicateIdEvaluate,

  // keyboard
  'accesskeys-after': accesskeysAfter,
  'accesskeys-evaluate': accesskeysEvaluate,
  'focusable-content-evaluate': focusableContentEvaluate,
  'focusable-disabled-evaluate': focusableDisabledEvaluate,
  'focusable-element-evaluate': focusableElementEvaluate,
  'focusable-modal-open-evaluate': focusableModalOpenEvaluate,
  'focusable-no-name-evaluate': focusableNoNameEvaluate,
  'focusable-not-tabbable-evaluate': focusableNotTabbableEvaluate,
  'landmark-is-top-level-evaluate': landmarkIsTopLevelEvaluate,
  'no-focusable-content-evaluate': noFocusableContentEvaluate,
  'tabindex-evaluate': tabindexEvaluate,

  // label
  'alt-space-value-evaluate': altSpaceValueEvaluate,
  'duplicate-img-label-evaluate': duplicateImgLabelEvaluate,
  'explicit-evaluate': explicitEvaluate,
  'help-same-as-label-evaluate': helpSameAsLabelEvaluate,
  'hidden-explicit-label-evaluate': hiddenExplicitLabelEvaluate,
  'implicit-evaluate': implicitEvaluate,
  'label-content-name-mismatch-evaluate': labelContentNameMismatchEvaluate,
  'multiple-label-evaluate': multipleLabelEvaluate,
  'title-only-evaluate': titleOnlyEvaluate,

  // landmarks
  'landmark-is-unique-after': landmarkIsUniqueAfter,
  'landmark-is-unique-evaluate': landmarkIsUniqueEvaluate,

  // language
  'has-lang-evaluate': hasLangEvaluate,
  'valid-lang-evaluate': validLangEvaluate,
  'xml-lang-mismatch-evaluate': xmlLangMismatchEvaluate,

  // lists
  'dlitem-evaluate': dlitemEvaluate,
  'listitem-evaluate': listitemEvaluate,
  'only-dlitems-evaluate': onlyDlitemsEvaluate,
  'only-listitems-evaluate': onlyListitemsEvaluate,
  'structured-dlitems-evaluate': structuredDlitemsEvaluate,

  // media
  'caption-evaluate': captionEvaluate,
  'frame-tested-evaluate': frameTestedEvaluate,
  'no-autoplay-audio-evaluate': noAutoplayAudioEvaluate,

  // rule matches
  'aria-allowed-attr-matches': ariaAllowedAttrMatches,
  'aria-allowed-role-matches': ariaAllowedRoleMatches,
  // @deprecated
  'aria-form-field-name-matches': noNamingMethodMatches,
  'aria-has-attr-matches': ariaHasAttrMatches,
  'aria-hidden-focus-matches': ariaHiddenFocusMatches,
  'aria-required-children-matches': ariaRequiredChildrenMatches,
  'aria-required-parent-matches': ariaRequiredParentMatches,
  'autocomplete-matches': autocompleteMatches,
  'bypass-matches': bypassMatches,
  'color-contrast-matches': colorContrastMatches,
  'data-table-large-matches': dataTableLargeMatches,
  'data-table-matches': dataTableMatches,
  'duplicate-id-active-matches': duplicateIdActiveMatches,
  'duplicate-id-aria-matches': duplicateIdAriaMatches,
  'duplicate-id-misc-matches': duplicateIdMiscMatches,
  'frame-focusable-content-matches': frameFocusableContentMatches,
  'frame-title-has-text-matches': frameTitleHasTextMatches,
  'heading-matches': headingMatches,
  'html-namespace-matches': htmlNamespaceMatches,
  'identical-links-same-purpose-matches': identicalLinksSamePurposeMatches,
  'inserted-into-focus-order-matches': insertedIntoFocusOrderMatches,
  'is-initiator-matches': isInitiatorMatches,
  'label-content-name-mismatch-matches': labelContentNameMismatchMatches,
  'label-matches': labelMatches,
  'landmark-has-body-context-matches': landmarkHasBodyContextMatches,
  'landmark-unique-matches': landmarkUniqueMatches,
  'layout-table-matches': layoutTableMatches,
  'link-in-text-block-matches': linkInTextBlockMatches,
  'nested-interactive-matches': nestedInteractiveMatches,
  'no-autoplay-audio-matches': noAutoplayAudioMatches,
  'no-empty-role-matches': noEmptyRoleMatches,
  'no-explicit-name-required-matches': noExplicitNameRequiredMatches,
  'no-naming-method-matches': noNamingMethodMatches,
  'no-role-matches': noRoleMatches,
  'not-html-matches': notHtmlMatches,
  'p-as-heading-matches': pAsHeadingMatches,
  'scrollable-region-focusable-matches': scrollableRegionFocusableMatches,
  'skip-link-matches': skipLinkMatches,
  'svg-namespace-matches': svgNamespaceMatches,
  'window-is-top-matches': windowIsTopMatches,
  'xml-lang-mismatch-matches': xmlLangMismatchMatches
};

export default metadataFunctionMap;
