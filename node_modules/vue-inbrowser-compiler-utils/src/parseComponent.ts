interface VsgSFCDescriptorSimple {
	template?: string
	script?: string
}

export interface VsgSFCDescriptor extends VsgSFCDescriptorSimple {
	styles?: string[]
}

// highest priority first
const PARTS: (keyof VsgSFCDescriptorSimple)[] = ['script', 'template']

export default function parseComponent(code: string): VsgSFCDescriptor {
	// reinintialize regexp after each tour
	const partsRE: { [partName: string]: RegExp } = PARTS.reduce(
		(ret: { [partName: string]: RegExp }, part: string) => {
			ret[part] = new RegExp(`<${part}[^>]*>((.|\\n|\\r)+)</${part}>`, 'g')
			return ret
		},
		{}
	)

	const descriptor: VsgSFCDescriptor = {}

	let codeCleaned = code

	// extract all parts
	PARTS.forEach(part => {
		const res = partsRE[part].exec(codeCleaned)
		if (res) {
			const partFound = res[0] as string

			const linesBeforePart = code.split(partFound)[0]
			const paddingLinesNumber = linesBeforePart.split('\n').length
			descriptor[part] = Array(paddingLinesNumber).join('\n') + res[1]

			// once we have extracted one part,
			// remove it from the analyzed blob
			const linesOfPart = partFound.split('\n').length
			codeCleaned = codeCleaned.replace(partFound, Array(linesOfPart).join('\n'))
		}
	})

	// we assume that
	const styleRE = /<style[^>]*>((.|\n|\r)*?)<\/style>/g
	let styleAnalyzed = ''
	const stylesWithWrapper: string[] = []
	let stylePart: RegExpExecArray | undefined | null = styleRE.exec(codeCleaned)
	let styles: string[] | undefined
	while (stylePart) {
		styleAnalyzed += stylePart[1]

		if (!styles) {
			styles = []
		}

		const styleWithWrapper = stylePart[0]
		stylesWithWrapper.push(styleWithWrapper)

		const linesBeforePart = code.split(styleWithWrapper)[0]
		const paddingLinesNumber = linesBeforePart.split('\n').length

		styles.push(Array(paddingLinesNumber).join('\n') + styleAnalyzed)

		stylePart = styleRE.exec(codeCleaned)
	}

	if (styles) {
		descriptor.styles = styles
		let j = styles.length
		while (j--) {
			codeCleaned = codeCleaned.replace(stylesWithWrapper[j], '').trim()
		}
	}

	return codeCleaned.trim().length ? {} : descriptor
}
