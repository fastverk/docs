# The platform

The products that sit on top of the constellation.

| | |
|---|---|
| [**fvkit**](https://github.com/fastverk/desktop/tree/main/fvkit) | core/runtime — the platform library + the `fvd` daemon (volumes, bazelrc, connections, maintenance, updater). Git vehicle: [`fastverk/desktop`](https://github.com/fastverk/desktop). |
| [**fastverk-app**](https://github.com/fastverk/desktop/tree/main/fastverk-app) | the macOS desktop app — a menu-bar control plane for the works. Same desktop vehicle. |
| [**brand**](https://github.com/fastverk/brand) | the visual identity — one parametric source for the mark, icons, brandbook, decks, and this docs theme |

Managed cloud RBE + cache, a WireGuard mesh, and source hosting compose on top:
the build, the network, the source, and the machine — reproducible and verified,
end to end.

Gateway and adapter implementations (`forge`, `tracker`, `service-finder`,
`wave`) live in [`fastverk/platform`](https://github.com/fastverk/platform).
Public protos live in [`fastverk/contracts`](https://github.com/fastverk/contracts).
See **[Ship vehicles](vehicles.md)** for the full map.

## Turnkey AWS install

The server side installs into *your own* AWS account in one launch — a single
CloudFormation stack brings up the cluster, nodes, TLS, and DNS, reachable at
your own domain with no manual steps. The plugin runtime (gRPC-service plugins,
discovered and routed like QueryRPC) lets features ship as narrowly-scoped
modules in [`plugin-shell`](https://github.com/fastverk/plugin-shell) without
forking the core.

## Keyless workload identity

CI gets a short-lived fastverk credential by exchanging its own OIDC token (no
shared secrets): the workload-identity broker verifies a GitHub Actions token and
mints a scoped, Cognito-backed token — the machine-identity sibling of the
interactive login.
