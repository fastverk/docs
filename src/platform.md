# The platform

The products that sit on top of the constellation.

| | |
|---|---|
| [**fvkit**](https://github.com/fastverk/fvkit) | core/runtime — the platform library + the `fvd` daemon (volumes, bazelrc, connections, maintenance, updater) |
| [**fastverk-app**](https://github.com/fastverk/fastverk-app) | the macOS desktop app — a menu-bar control plane for the works |
| [**brand**](https://github.com/fastverk/brand) | the visual identity — one parametric source for the mark, icons, brandbook, decks, and this docs theme |

Managed cloud RBE + cache, a WireGuard mesh, and source hosting compose on top:
the build, the network, the source, and the machine — reproducible and verified,
end to end.

## Turnkey AWS install

The server side installs into *your own* AWS account in one launch — a single
CloudFormation stack brings up the cluster, nodes, TLS, and DNS, reachable at
your own domain with no manual steps. The plugin runtime (gRPC-service plugins,
discovered and routed like QueryRPC) lets features ship as narrowly-scoped repos
without forking the core.

## Keyless workload identity

CI gets a short-lived fastverk credential by exchanging its own OIDC token (no
shared secrets): the workload-identity broker verifies a GitHub Actions token and
mints a scoped, Cognito-backed token — the machine-identity sibling of the
interactive login.
