package admin

import (
	"html/template"
	"net/url"
	"strconv"
	"strings"

	"github.com/DEV-Johnstocker/chatwoot/ai-service/internal/knowledge"
)

// maxQueryRunes bounds the knowledge search box.
const maxQueryRunes = 200

// libraryFilter is how the owner is looking at the knowledge library: a
// search, a type, a status filter and grid or list. Links and forms carry it
// so Edit, Save and Delete come back to the same view.
type libraryFilter struct {
	Query string
	Type  string // "", "faq", "doc", "synced"
	Show  string // "", "unused", "inactive"
	View  string // "" (grid) or "list"
}

// parseLibrary reads the filter from a query or a posted form, keeping only
// known values, so the filter is safe to put back into a redirect.
func parseLibrary(v url.Values) libraryFilter {
	f := libraryFilter{Show: listFilter(v.Get("show"))}
	if q := []rune(strings.TrimSpace(v.Get("q"))); len(q) > maxQueryRunes {
		f.Query = string(q[:maxQueryRunes])
	} else {
		f.Query = string(q)
	}
	switch t := v.Get("type"); t {
	case "faq", "doc", "synced":
		f.Type = t
	}
	if v.Get("view") == "list" {
		f.View = "list"
	}
	return f
}

// Params is the filter as "&k=v" pairs to append after "?account=N",
// leaving out defaults.
func (f libraryFilter) Params() string {
	var b strings.Builder
	add := func(k, v string) {
		if v != "" {
			b.WriteString("&" + k + "=" + url.QueryEscape(v))
		}
	}
	add("q", f.Query)
	add("type", f.Type)
	add("show", f.Show)
	add("view", f.View)
	return b.String()
}

// URL is the library page for an account with this filter. The values were
// whitelisted or query-escaped by parseLibrary and Params, so the template
// may use it as a URL as is.
func (f libraryFilter) URL(acct int64) template.URL {
	return template.URL("/admin/knowledge?account=" + strconv.FormatInt(acct, 10) + f.Params())
}

// With is the library URL with one field changed: "type", "show" or "view";
// "all" clears type and status; "clear" also clears the search.
func (f libraryFilter) With(acct int64, field, value string) template.URL {
	switch field {
	case "type":
		f.Type = value
	case "show":
		f.Show = value
	case "view":
		f.View = value
	case "all":
		f.Type, f.Show = "", ""
	case "clear":
		f.Query, f.Type, f.Show = "", "", ""
	}
	return f.URL(acct)
}

// Edit is the edit page for one document, keeping the filter.
func (f libraryFilter) Edit(acct, id int64) template.URL {
	return f.URL(acct) + template.URL("&edit="+strconv.FormatInt(id, 10))
}

// Back returns to one document's card in the library.
func (f libraryFilter) Back(acct, id int64) template.URL {
	return f.URL(acct) + template.URL("#doc-"+strconv.FormatInt(id, 10))
}

// Active reports whether a search or filter narrows the list.
func (f libraryFilter) Active() bool { return f.Query != "" || f.Type != "" || f.Show != "" }

// docType sorts a document into exactly one library type, so the type counts
// add up to the total: website or data-file rows first, then FAQ or document.
func docType(d knowledge.Document) string {
	switch {
	case knowledge.SyncedKey(d.SourceKey):
		return "synced"
	case d.Kind == knowledge.KindFAQ:
		return "faq"
	}
	return "doc"
}

// match reports whether a document passes the filter.
func (f libraryFilter) match(d knowledge.Document, v docView) bool {
	if f.Type != "" && f.Type != docType(d) {
		return false
	}
	if (f.Show == "unused" && !v.Unused) || (f.Show == "inactive" && v.Status == knowledge.StatusActive) {
		return false
	}
	if f.Query != "" {
		q := strings.ToLower(f.Query)
		return strings.Contains(strings.ToLower(d.Title), q) || strings.Contains(strings.ToLower(d.Content), q)
	}
	return true
}
