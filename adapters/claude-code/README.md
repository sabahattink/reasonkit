# Claude Code Adapter

This directory contains the copy/load surface for a Claude Code host. Start
with SKILL.md and load the generated bundle from dist/.

## Required interface

An implementation should map the ReasonKit skill, protocols, bounded
specialist calls, tool permissions, verification result, and stop policy onto
the host environment. It must keep the hub-and-spoke topology and expose
provider-specific details only inside this adapter.

## Scope

This is a prompt-pack adapter, not a provider runtime. No Claude Code
integration or capability claim is made beyond the documented loading seam.
