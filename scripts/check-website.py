#!/usr/bin/env python3
"""Dependency-free validation for the public MOME product page."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

root = Path(__file__).resolve().parent.parent
site = root / "site"
html = site / "index.html"

class Inspector(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.refs = []
        self.controls = []
        self.assets = []
        self.blank_links = []

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            assert attrs["id"] not in self.ids, f"Duplicate id {attrs['id']}"
            self.ids.add(attrs["id"])
        if tag == "a":
            href = attrs.get("href", "")
            assert href, "Empty anchor destination"
            if href.startswith("#"):
                self.refs.append(href[1:])
            if attrs.get("target") == "_blank":
                self.blank_links.append(attrs)
        if tag in ("script", "link"):
            path = attrs.get("src") or attrs.get("href", "")
            if path.startswith("./"):
                self.assets.append(path[2:])
        if attrs.get("role") == "tab":
            self.controls.append(attrs)

parser = Inspector()
source = html.read_text(encoding="utf-8")
parser.feed(source)
for reference in parser.refs:
    assert reference in parser.ids, f"Missing in-page target {reference}"
for asset in parser.assets:
    assert (site / asset).is_file(), f"Missing static asset {asset}"
for attrs in parser.blank_links:
    rel = set(attrs.get("rel", "").split())
    assert {"noopener", "noreferrer"}.issubset(rel), "Unsafe target=_blank link"
for control in parser.controls:
    assert control.get("aria-controls") in parser.ids, "Broken tab reference"
assert len(parser.controls) == 3, "Expected three keyboard-accessible dashboard tabs"
assert "ILLUSTRATIVE DATA" in source and "PUBLIC PREVIEW IN PREPARATION" in source, "Missing truthful preview disclosure"
for forbidden in ("<form", 'type="password"', "sk_test_", "sk_live_"):
    assert forbidden not in source, f"Unexpected sensitive or collection surface: {forbidden}"
print(f"Website checks passed: {len(parser.ids)} IDs, {len(parser.refs)} anchors, {len(parser.controls)} tabs, {len(parser.assets)} assets")
