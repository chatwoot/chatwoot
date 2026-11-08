package main

import "testing"

func TestAdminBaseURL(t *testing.T) {
	cases := map[string]string{
		"https://support.example.com/mcp":      "https://support.example.com",
		"https://support.example.com:8443/mcp": "https://support.example.com:8443",
		"http://127.0.0.1:8090/mcp":            "http://127.0.0.1:8090",
		"http://support.example.com/mcp":       "", // plain http off-machine
		"https://user:pw@support.example.com":  "", // credentials in the address
		"javascript:alert(1)":                  "",
		"":                                     "",
		"/mcp":                                 "",
	}
	for in, want := range cases {
		// Act
		got := adminBaseURL(in)

		// Assert
		if got != want {
			t.Errorf("adminBaseURL(%q) = %q, want %q", in, got, want)
		}
	}
}
