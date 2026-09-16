# Distribution

The distribution files are the copy/load surface for ReasonKit:

- reasonkit.md is the full generated bundle.
- reasonkit-min.md is the compact bundle for tight context windows.

Regenerate them with scripts/build-dist.ps1. CI checks that generated output
matches the source files. Provider-specific loading notes live under
adapters/.
