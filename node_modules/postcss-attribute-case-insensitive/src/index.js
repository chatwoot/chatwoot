import postcss from 'postcss';
import parser from 'postcss-selector-parser';

function nodeIsInsensitiveAttribute(node) {
	return node.type === 'attribute' && node.insensitive;
}

function selectorHasInsensitiveAttribute(selector) {
	return selector.some(nodeIsInsensitiveAttribute);
}

function transformString(strings, charPos, string) {
	const char = string.charAt(charPos);
	if (char === '') {
		return strings;
	}

	let newStrings = strings.map(x => x + char);
	const upperChar = char.toLocaleUpperCase();

	if (upperChar !== char) {
		newStrings = newStrings.concat(strings.map(x => x + upperChar));
	}

	return transformString(newStrings, charPos + 1, string);
}

function createSensitiveAtributes(attribute) {
	const attributes = transformString([''], 0, attribute.value);
	return attributes.map(x => {
		const newAttribute = attribute.clone({
			spaces: {
				after: attribute.spaces.after,
				before: attribute.spaces.before
			},
			insensitive: false
		});

		newAttribute.setValue(x);

		return newAttribute;
	});
}

function createNewSelectors(selector) {
	let newSelectors = [parser.selector()];

	selector.walk(node => {
		if (!nodeIsInsensitiveAttribute(node)) {
			newSelectors.forEach(newSelector => {
				newSelector.append(node.clone());
			});
			return;
		}

		const sensitiveAttributes = createSensitiveAtributes(node);
		const newSelectorsWithSensitiveAttributes = [];

		sensitiveAttributes.forEach(newNode => {
			newSelectors.forEach(newSelector => {
				const newSelectorWithNewNode = newSelector.clone();
				newSelectorWithNewNode.append(newNode);
				newSelectorsWithSensitiveAttributes.push(newSelectorWithNewNode);
			});
		});

		newSelectors = newSelectorsWithSensitiveAttributes;
	});

	return newSelectors;
}

function transform(selectors) {
	let newSelectors = [];

	selectors.each(selector => {
		if (selectorHasInsensitiveAttribute(selector)) {
			newSelectors = newSelectors.concat(createNewSelectors(selector));
			selector.remove();
		}
	});

	if (newSelectors.length) {
		newSelectors.forEach(newSelector => selectors.append(newSelector));
	}
}

const caseInsensitiveRegExp = /i(\s*\/\*[\W\w]*?\*\/)*\s*\]/;

export default postcss.plugin('postcss-attribute-case-insensitive', () => css => {
	css.walkRules(caseInsensitiveRegExp, rule => {
		rule.selector = parser(transform).processSync(rule.selector);
	});
});
