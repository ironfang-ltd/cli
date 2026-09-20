# Financewolf report protocol v1

## Version 1 signature protocol

The result, public-key and request schemas are published in the Financewolf
OpenAPI contract. The verifier checks the exact stored manifest bytes rather than
reserializing caller-supplied JSON.

- Manifest schema: `financewolf/einvoice/report-manifest/v1`.
- Product: `financewolf-einvoicing`.
- Canonicalization: `financewolf-report-json/1`: compact Go `encoding/json` of the
  declared struct fields in declaration order, HTML-safe string escaping, integer
  numbers and UTC RFC3339Nano times. This is **not** RFC 8785/JCS. Arrays retain
  their declared order; artifact descriptors sort by filename. Do not reserialize
  the manifest when verifying its signature. Future incompatible changes require
  a new schema/canonicalization version and continued support for existing v1
  signatures, not silent regeneration of historical vectors.
- Signed message: UTF-8 `financewolf/einvoice/report-signature/v1`, then one NUL
  byte (`00`), then the exact canonical `manifest.json` bytes.
- Algorithm: Ed25519, using the existing Auditwolf signing-service primitive.
  Financewolf's schema, domain separator and signature envelope are separate;
  Auditwolf raw-manifest signatures cannot pass Financewolf verification.
- Public key ID: `fw_ed25519_` followed by all 64 lowercase hex characters of
  SHA-256(public-key bytes). Public keys and signatures use unpadded standard base64.
- Signature envelope schema: `financewolf/einvoice/report-signature/v1`. Its key
  ID/algorithm must match the signed manifest. It carries no self-trusted key.
- Every artifact descriptor names exact bytes and length plus lowercase SHA-256.
  The readable HTML is deterministic from the signed manifest and checked byte
  for byte, avoiding a self-referential HTML/manifest hash.

The manifest records operation and optional existing document ID, source/output
hashes, exact profile/ruleset/VES, lifecycle state **at validation**, immutable
release names and three executable artifact checksums, original validator engine
and image digest, generator/render versions where applicable, all five layer
outcomes, complete finding count, original validation times and issuance time.
It does not manufacture a document ID or infer historical dependency versions
from a current engine. Original JSON is not retained; its canonical hash is.

## Timestamp policy

The default signed policy is `none`; issuance time is then a service assertion.
When a TSA is explicitly configured, the signed policy is `required`. The TSA
receives only SHA-256(domain-separated signed message), never invoice content.
The issuer verifies the query imprint and the returned token through OpenSSL
with an operator-supplied CA before releasing the bundle. Verification requires
that same imprint binding and an independently trusted TSA CA. Stripping either
file, changing the token or omitting CA trust fails verification.

The implementation reuses Auditwolf's RFC 3161 client/query parsing and local
OpenSSL verifier. The real OpenSSL test creates a temporary synthetic TSA and
checks both valid and tampered tokens. The public verifier makes no network calls,
including TSA calls. No production TSA endpoint is selected by this change.

## Verification and trust

`POST /financewolf/v1/einvoices/reports/verify` takes raw `application/zip`, without
an account, key or subscription. HTTP 200 reports `verified: true|false`;
`invoice_outcome` is returned only after successful integrity verification. A
verified report can record an **invalid invoice**. Verification never reruns PHIVE.
The response distinguishes signature, artifact hashes and timestamp checks.

`GET /financewolf/v1/einvoices/reports/keys` publishes operator-configured public
keys with `active`, `retired` or `revoked` status. Empty means no keys configured.
Retired keys verify historical reports; revoked and unknown keys fail closed.
Keys are loaded at process startup; restart all API replicas after trust-file
changes and verify the public endpoint. Cache lifetime is 300 seconds. Trust comes from independently obtaining this key
set, not from a field in an uploaded ZIP. Offline users must maintain revocation
updates; this protocol does not prove a key was uncompromised at an asserted time.

The public browser at `/financewolf/verify` explicitly discloses that clicking
Verify uploads the entire bundle transiently to Financewolf. Choosing a file does
not submit it. No document URLs are fetched, uploads retained or files forwarded.


## Resource and privacy boundaries

Requests and expanded ZIPs are capped at 48 MiB. Central-directory byte/count
limits are checked before Go's ZIP parser allocates member objects. Only single
disk ZIP32 with no archive comment is supported. At most nine exact member names
are accepted. Duplicate paths, directories, symlinks, encryption, unknown names,
unsigned extras, unsupported compression and CRC/length mismatches are rejected.
Individual limits: result 16 MiB, findings 8 MiB, XML 5 MiB, PDF 32 MiB, manifest
and signature 64 KiB each, HTML 256 KiB and each TSA file 1 MiB. Their combined
expanded size must still fit within 48 MiB.

Two issuance and two verification slots per API process bound concurrent input
and artifact memory. PDF work also shares the existing two render slots. Issuance
has a 45-second deadline, public verification 15 seconds and the CLI 30 seconds.
Address/anonymous/key limits run before expensive work. Metrics use bounded
surface/outcome labels, with separate report/verification counters, durations and
inflight gauges; no invoice content or key material is logged.

