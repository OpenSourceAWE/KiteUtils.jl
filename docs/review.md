<!--
SPDX-FileCopyrightText: 2026 Uwe Fechner
SPDX-License-Identifier: CC-BY-4.0
-->

# Code review of KiteUtils v0.13.2

Review of the `main` branch at commit `e81a722`, October 2026. The full test suite passed
before any change; Transformations has 2 tests marked broken, as on `main`.

The four bugs below were reproduced with a script and are fixed, each with a regression
test, in the pull request that adds this file. The remaining items are not fixed yet.

## Bugs (fixed)

### 1. `set_data_path` did not force a reload of the settings

[src/settings.jl](../src/settings.jl) contained `SETTINGS.segments == 0`, a comparison,
where an assignment was intended. After pointing the data path at a directory whose
`settings.yaml` has `segments: 13`, `se()` still returned the cached value 6; only an
explicit `load_settings` returned 13.

**Fix:** a plain `SETTINGS.segments = 0` is not enough. The tests, and probably
downstream code, point the data path at a directory that only holds log files (for example
`tempdir()`) and then call `se()`, for example through `demo_log`. A reload pending from an
earlier `set_data_path` would then fail on the missing `system.yaml`. Instead, the global
settings now remember the directory they were loaded from. After `set_data_path`, the next
`se()` reloads them once if the new directory contains the active project file; a directory
holding only log files keeps the loaded settings. The check runs only once after each path
change, so `se()` stays cheap.

### 2. `Settings(project)` changed the global settings

The docstring of `Settings(project)` promises an independent instance that does not
touch the global settings, but `se(settings, project)` wrote the global `PROJECT` for
every instance. Reproduced:

```julia
se("system.yaml")
other = Settings("system_ram.yaml")
se()               # contents of settings.yaml, but PROJECT == "system_ram.yaml"
update_settings()  # silently switches the global SETTINGS to the ram project
```

So `se()` returned stale settings under the wrong project name, and the next
`update_settings()` changed the global settings to a different project.

**Fix:** only loading the global `SETTINGS` updates `PROJECT`. Independent instances
record the project they were loaded from in `_SE_PROJECTS`. When `se(settings)` is called
without a project, it uses that instance's own project.

### 3. `demo_state_4p` ignored its `time` argument

`demo_state_4p(P, height, time)` wrote `time` into `t_sim`, so `state.time` was always 0.
The docstring gave the default as `0.0`, while the signature used `0.014`.

**Fix:** `time` (default `0.0`) goes into `time`; `t_sim` keeps the demo value `0.014`
that the existing tests expect.

### 4. `ENU2EG` was a non-`const` global

[src/trafo.jl](../src/trafo.jl) defined `ENU2EG` without `const`, so `fromENU2EG`,
`calc_heading`, `calc_heading_w` and `calc_course` could not be type-inferred.

**Fix:** `const ENU2EG`. The test now checks `@inferred fromENU2EG(...)`.

## Maintenance issues (open)

- **Dead generated file.** `src/build.jl` generates `src/_load_log.jl`, but nothing
  includes it. It uses `K`, `W`, `S`, `N` and `F` without defining them, and builds
  `colmeta` in the old format. Stop generating it, or delete it.
- **Aqua never runs.** `test/aqua.jl` does not match the `test-*.jl` pattern of
  `test/runtests.jl`, and no workflow runs it, although Aqua is a test dependency.
- **Stale docstrings.**
  - `calc_course` documents a parameter `down_wind_direction`; the function takes
    `upwind_dir`.
  - The loose string `"""Functions to transform between coordinate systems."""` at the
    top of `src/trafo.jl` becomes the docstring of `ENU2EG`.
  - `calculate_rotational_inertia` calls Ixy "rotational inertia around the xy-plane".
    It is the product of inertia, computed as +Σ m·x·y, and the docstring should say
    which sign convention it uses.
- **Leftover global.** `P = nothing` in `src/KiteUtils.jl`.
- **`load_log` robustness.**
  - The log name is derived with `fullname[1:end-6]`, which assumes the extension
    `.arrow`; `transition.arrow2` comes back named `"transition."`.
  - The metadata of `var_01` … `var_16` is read unconditionally, so a log without those
    columns fails with a `MethodError`, while the column reader zero-fills missing
    columns elsewhere.
  - A log already in `KA` keeps its read-only Arrow columns; a converted `KS` log gets
    mutable ones.
- **YAML helpers.**
  - `update_yaml_scalar` escapes its key with `escape_string`, which does not escape
    regex metacharacters. It also matches the first line with that key in any section.
  - `change_value` indexes strings by byte, so a non-ASCII value fails. It also silently
    truncates a value that is longer than the old one. The only current caller, which
    sets `fixed_font` in `copy_settings`, fits.
- **Memory.** `_SE_DICTS`, and now `_SE_PROJECTS`, are `IdDict`s keyed by `Settings`
  instance, so every instance created with `Settings(project)` stays in memory for good.
  A `WeakKeyDict` would avoid that, but needs care because these dicts are filled during
  precompilation.
- **Side effects.**
  - `install_examples` runs `Pkg.add` in the user's active environment.
  - `menu()` includes `examples/menu.jl` relative to the current directory.

## Strengths

- The KS/KA frame-convention work is careful:
  - logs declare their convention;
  - an unknown declaration is refused rather than guessed;
  - every body-resolved column is converted exactly once, when a log is loaded.
- Older log formats load cleanly: missing columns are zero-filled and fixed-width
  columns are resized to the counts in the file.
- The test suite is thorough, with about 28,700 tests, many of them round-trip tests of
  frames and logs.
- The changelog is detailed and up to date.
