import { describe, it, expect } from "vitest";

function buildInstagramURL(username) {
  return `https://www.instagram.com/${username}`;
}

describe("Instagram profile URL", () => {
  it("formats instagram profile URL correctly", () => {
    const url = buildInstagramURL("chatwoot");
    expect(url).toBe("https://www.instagram.com/chatwoot");
  });
});
