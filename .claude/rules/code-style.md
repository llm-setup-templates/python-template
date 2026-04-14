# Code Style Rules

## Universal
- Indent size: 4
- Line length limit: 88 (Ruff default)
- Trailing commas: all (Ruff format default)
- End of line: LF (enforced via .gitattributes)
- File encoding: UTF-8

## Formatter ownership
- The formatter (Ruff format) owns all whitespace / layout concerns.
- The linter (Ruff lint) owns semantic / logic rules only.
- Style rules that conflict between the two must be disabled in the linter.

## Naming
- Functions/variables: snake_case
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE
- Type aliases: PascalCase
- Private: _leading_underscore

## Imports
- Absolute imports preferred (`from my_project.x import y`)
- Relative imports allowed only within the same package
- Import order: stdlib → third-party → local (Ruff `I` category enforces)
- No wildcard imports (`F403` rule blocks)
