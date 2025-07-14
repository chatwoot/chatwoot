const name = "jinja-html";
const scopeName = "text.html.jinja";
const comment = "Jinja HTML Templates";
const firstLineMatch = "^{% extends [\"'][^\"']+[\"'] %}";
const foldingStartMarker = "(<(?i:(head|table|tr|div|style|script|ul|ol|form|dl))\\b.*?>|{%\\s*(block|filter|for|if|macro|raw))";
const foldingStopMarker = "(</(?i:(head|table|tr|div|style|script|ul|ol|form|dl))\\b.*?>|{%\\s*(endblock|endfilter|endfor|endif|endmacro|endraw)\\s*%})";
const patterns = [
	{
		include: "source.jinja"
	},
	{
		include: "text.html.basic"
	}
];
const jinjaHtml_tmLanguage = {
	name: name,
	scopeName: scopeName,
	comment: comment,
	firstLineMatch: firstLineMatch,
	foldingStartMarker: foldingStartMarker,
	foldingStopMarker: foldingStopMarker,
	patterns: patterns
};

export { comment, jinjaHtml_tmLanguage as default, firstLineMatch, foldingStartMarker, foldingStopMarker, name, patterns, scopeName };
