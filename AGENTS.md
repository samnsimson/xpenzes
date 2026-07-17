# Agent rules for xpenzes-app

These are binding conventions for any AI coding agent (Claude Code, Cursor,
or otherwise) working in this repository.

## Commit once changes are verified

Once a task's changes are complete and actually verified — `flutter
analyze` is clean, and/or the behavior was exercised for real (ran on a
simulator/device, a smoke test against xpenzes-svc) rather than assumed
to work — commit them without waiting to be asked each time. Use your
judgment on commit boundaries (one logical commit per task, split
further if the diff naturally covers more than one concern) and write
the message the same way you always do. This does not extend to pushing
to a remote — that still needs an explicit ask.
