// Matches strings that look like dates using "/" as a separator.
// Examples: 3/10/2011, 31/10/96 or 08/31/95.
const SLASH_SEPARATED_DATES = /(?:(?:[0-3]?\d\/[01]?\d)|(?:[01]?\d\/[0-3]?\d))\/(?:[12]\d)?\d{2}/

// Matches timestamps.
// Examples: "2012-01-02 08:00".
// Note that the reg-ex does not include the
// trailing ":\d\d" -- that is covered by TIME_STAMPS_SUFFIX.
const TIME_STAMPS = /[12]\d{3}[-/]?[01]\d[-/]?[0-3]\d +[0-2]\d$/
const TIME_STAMPS_SUFFIX_LEADING = /^:[0-5]\d/

export default function isValidPreCandidate(candidate, offset, text)
{
	// Skip a match that is more likely to be a date.
	if (SLASH_SEPARATED_DATES.test(candidate)) {
		return false
	}

	// Skip potential time-stamps.
	if (TIME_STAMPS.test(candidate))
	{
		const followingText = text.slice(offset + candidate.length)
		if (TIME_STAMPS_SUFFIX_LEADING.test(followingText)) {
			return false
		}
	}

	return true
}