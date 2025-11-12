const $schema = "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json";
const name = "mdx";
const patterns = [
	{
		include: "#jsx"
	},
	{
		include: "#markdown"
	}
];
const repository = {
	jsx: {
		patterns: [
			{
				include: "#jsx-module"
			},
			{
				include: "#jsx-tag"
			}
		],
		repository: {
			"jsx-module": {
				patterns: [
					{
						begin: "^(?=(import|export)\\b)",
						"while": "^(?!\\s*$)",
						contentName: "source.js.jsx",
						patterns: [
							{
								include: "source.js.jsx"
							}
						]
					}
				]
			},
			"jsx-tag": {
				patterns: [
					{
						begin: "^(?=<([a-z]|[A-Z]))",
						end: "(?<=>)",
						contentName: "source.js.jsx",
						patterns: [
							{
								include: "source.js.jsx"
							}
						]
					}
				]
			}
		}
	},
	markdown: {
		contentName: "text.html.markdown",
		patterns: [
			{
				include: "text.html.markdown"
			}
		]
	}
};
const scopeName = "text.html.markdown.jsx";
const mdx_tmLanguage = {
	$schema: $schema,
	name: name,
	patterns: patterns,
	repository: repository,
	scopeName: scopeName
};

export { $schema, mdx_tmLanguage as default, name, patterns, repository, scopeName };
