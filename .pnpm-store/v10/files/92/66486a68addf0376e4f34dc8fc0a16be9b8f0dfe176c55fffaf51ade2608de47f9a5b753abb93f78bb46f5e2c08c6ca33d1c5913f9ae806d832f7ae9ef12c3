const fileTypes = [
	"erb",
	"rhtml",
	"html.erb"
];
const injections = {
	"text.html.erb - (meta.embedded.block.erb | meta.embedded.line.erb | comment)": {
		patterns: [
			{
				begin: "(^\\s*)(?=<%+#(?![^%]*%>))",
				beginCaptures: {
					"0": {
						name: "punctuation.whitespace.comment.leading.erb"
					}
				},
				end: "(?!\\G)(\\s*$\\n)?",
				endCaptures: {
					"0": {
						name: "punctuation.whitespace.comment.trailing.erb"
					}
				},
				patterns: [
					{
						include: "#comment"
					}
				]
			},
			{
				begin: "(^\\s*)(?=<%(?![^%]*%>))",
				beginCaptures: {
					"0": {
						name: "punctuation.whitespace.embedded.leading.erb"
					}
				},
				end: "(?!\\G)(\\s*$\\n)?",
				endCaptures: {
					"0": {
						name: "punctuation.whitespace.embedded.trailing.erb"
					}
				},
				patterns: [
					{
						include: "#tags"
					}
				]
			},
			{
				include: "#comment"
			},
			{
				include: "#tags"
			}
		]
	}
};
const keyEquivalent = "^~H";
const name = "erb";
const patterns = [
	{
		include: "text.html.basic"
	}
];
const repository = {
	comment: {
		patterns: [
			{
				begin: "<%+#",
				beginCaptures: {
					"0": {
						name: "punctuation.definition.comment.begin.erb"
					}
				},
				end: "%>",
				endCaptures: {
					"0": {
						name: "punctuation.definition.comment.end.erb"
					}
				},
				name: "comment.block.erb"
			}
		]
	},
	tags: {
		patterns: [
			{
				begin: "<%+(?!>)[-=]?(?![^%]*%>)",
				beginCaptures: {
					"0": {
						name: "punctuation.section.embedded.begin.erb"
					}
				},
				contentName: "source.ruby",
				end: "(-?%)>",
				endCaptures: {
					"0": {
						name: "punctuation.section.embedded.end.erb"
					},
					"1": {
						name: "source.ruby"
					}
				},
				name: "meta.embedded.block.erb",
				patterns: [
					{
						captures: {
							"1": {
								name: "punctuation.definition.comment.erb"
							}
						},
						match: "(#).*?(?=-?%>)",
						name: "comment.line.number-sign.erb"
					},
					{
						include: "source.ruby"
					}
				]
			},
			{
				begin: "<%+(?!>)[-=]?",
				beginCaptures: {
					"0": {
						name: "punctuation.section.embedded.begin.erb"
					}
				},
				contentName: "source.ruby",
				end: "(-?%)>",
				endCaptures: {
					"0": {
						name: "punctuation.section.embedded.end.erb"
					},
					"1": {
						name: "source.ruby"
					}
				},
				name: "meta.embedded.line.erb",
				patterns: [
					{
						captures: {
							"1": {
								name: "punctuation.definition.comment.erb"
							}
						},
						match: "(#).*?(?=-?%>)",
						name: "comment.line.number-sign.erb"
					},
					{
						include: "source.ruby"
					}
				]
			}
		]
	}
};
const scopeName = "text.html.erb";
const uuid = "13FF9439-15D0-4E74-9A8E-83ABF0BAA5E7";
const erb_tmLanguage = {
	fileTypes: fileTypes,
	injections: injections,
	keyEquivalent: keyEquivalent,
	name: name,
	patterns: patterns,
	repository: repository,
	scopeName: scopeName,
	uuid: uuid
};

export { erb_tmLanguage as default, fileTypes, injections, keyEquivalent, name, patterns, repository, scopeName, uuid };
