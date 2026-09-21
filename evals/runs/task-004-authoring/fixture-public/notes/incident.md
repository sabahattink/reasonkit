# Incident note

The operator saw the service name from one workspace after switching to a
second workspace that used the same `development` profile. The diagnostic
label only prints a profile name, so it does not prove that the profile file
was selected correctly.

The expected behavior is to reuse a base configuration only when its
workspace and profile identify the same source. Per-request environment and
explicit overrides remain call-local.
