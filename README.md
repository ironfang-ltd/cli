# ironfang

The Ironfang command-line client. One binary, a subcommand per product:

| Command | What it does |
|---|---|
| `ironfang render` | Screenshots, PDFs, QR codes and clips from the Ironfang Render API |
| `ironfang rig` | Disposable external integration environments: sync a suite, start a run, wait on events, download evidence |
| `ironfang rig connect` | The connector that forwards a run's callbacks to services on your machine |
| `ironfang audit verify` | Verify an Ironfang Audit evidence bundle offline |
| `ironfang finance verify` | Verify a signed Ironfang Finance report bundle offline |

Releases live here: <https://github.com/ironfang-ltd/cli/releases>. Each
release carries a checksum file; verify a download before running it.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ironfang-ltd/cli/main/install.sh | sh
```

The script downloads the archive for your platform, checks it against the
release's `ironfang_<version>_checksums.txt`, and puts `ironfang` in
`~/.local/bin` (or the directory in `IRONFANG_INSTALL_DIR`). Or fetch an
archive from the releases page yourself:

```sh
sha256sum -c ironfang_<version>_checksums.txt --ignore-missing
tar -xzf ironfang_<version>_linux_amd64.tar.gz
```

Linux and macOS on amd64 and arm64, and Windows on amd64.

## Authenticate

`ironfang render` and `ironfang rig` need a platform API key. Mint one in the
portal at <https://portal.ironfang.uk> with the scopes the product needs, and
give it to the CLI through the environment or a file, never as an argument:

```sh
export IRONFANG_API_KEY=if_live_...
ironfang render screenshot https://example.com -o page.png

ironfang rig run --api-key-file ~/.config/ironfang/key -- npm run test:e2e
```

`IRONFANG_API_URL` overrides the API address (default `https://api.ironfang.uk`).
The connector uses a single-use bootstrap token instead, minted for one run:

```sh
IRONFANG_CONNECT_TOKEN=ift_boot_... ironfang rig connect --route stripe=http://127.0.0.1:8080/webhooks/stripe
```

## Verify offline

The verifiers contact nothing. Their trust anchors must come from a channel
independent of the bundle; a key embedded in the bundle proves nothing.

```sh
ironfang audit verify -bundle evidence.zip -trusted-public-key key.txt
ironfang finance verify -bundle report.zip -trusted-keys report-keys.json
```

Exit codes: 0 valid, 1 invalid, 2 usage. The Finance report bundle layout is
in `REPORT-FORMAT.md`.

## Documentation

- Render: <https://ironfang.uk/render/docs>
- Rig: <https://ironfang.uk/rig/docs>
- Audit: <https://ironfang.uk/audit/docs>
- Finance: <https://ironfang.uk/docs/finance>

This repository holds releases only; the source is Ironfang Ltd's private
monorepo. Go's licence for the compiled binary is in `GO-LICENSE.txt`.
