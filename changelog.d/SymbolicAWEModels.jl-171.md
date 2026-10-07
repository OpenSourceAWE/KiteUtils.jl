### Added

- `set_output_path(output_path="")` and `get_output_path()`, the folder `save_log`, `load_log`, `export_log` and `import_log` use when no `path` is passed: the data folder until `set_output_path` names another, which `get_output_path` creates when it is missing.
- `path`, a keyword of `import_log`, as `load_log` already has.
