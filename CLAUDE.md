# ctOS

A Watch Dogs ctOS–themed Linux rice: Quickshell (QML) bar and greetd greeter, plus themed configs in `extras/`.

## Design system

Read [`DESIGN.md`](DESIGN.md) before any visual or UI work.

- `design/tokens.json` is the source of truth for colors, type, spacing, shape and motion.
- `common/Theme.qml` and every file rendered from `design/templates/` are **generated**. Never edit them by hand. Change the tokens or template, then run `python3 design/build.py`.
- No color, size or duration literals in QML. Use `Theme.<token>`, and add a token if none fits.
- Reuse existing components (`common/components`, `bar/components`, `greeter/components`) before writing new ones.

## Conventions

- QML formatting follows `.qmlformat.ini` (4-space indent).
- Commits use conventional commits with a scope: `feat(bar): …`, `fix(greeter): …`, `feat(design): …`.
