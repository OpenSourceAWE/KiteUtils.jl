### Added

- `set_output_path(output_path="output")` and `get_output_path()`, the folder simulation results go to; `get_output_path` creates it when it is missing, and a relative path is taken from the working directory.
- `path`, a keyword of `import_log`, as `load_log` already has.

### Changed

- BREAKING: `save_log`, `load_log`, `export_log` and `import_log` use `get_output_path()` when no `path` is passed, where they used `get_data_path()`, so the data folder holds input only. Reading a log shipped in the data folder takes `path=get_data_path()`.
