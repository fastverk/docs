# Quick start

Wire the fastverk registry into your Bazel build, then add the modules you need.

## 1. Add the registry chain

`.bazelrc`:

```
common --registry=https://raw.githubusercontent.com/fastverk/bazel-registry/main/
common --registry=https://bcr.bazel.build/
```

## 2. Depend on modules

`MODULE.bazel`:

```python
bazel_dep(name = "rules_uv", version = "0.7.4")
bazel_dep(name = "rules_cloudformation", version = "0.8.0")
# … etc.
```

See each module's API reference for module-specific setup (toolchains,
extensions, `use_repo`).

## 3. Build

```sh
bazel build //...
```

A fresh checkout / CI resolves every fastverk module from the registry — no git
submodules, no `local_path_override`. To hack on one locally, override it ad hoc:

```sh
bazel build //… --override_module=<name>=path/to/<name>
```
