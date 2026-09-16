# Distribution

The distribution files are the copy/load surface for ReasonKit:

- reasonkit-min.md is the default compact bundle.
- reasonkit-coding.md is the coding bundle.
- reasonkit-debugging.md is the debugging bundle.
- reasonkit-design.md is the design and creative bundle.
- reasonkit-research.md is the research bundle.
- reasonkit-full.md is the complete bundle for explicit escalation only.

Regenerate them with scripts/build-dist.ps1. CI checks that generated output
matches the source files. Provider-specific loading notes live under
adapters/.
