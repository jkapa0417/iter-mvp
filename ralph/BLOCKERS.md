# Blockers — ITER MVP

> Features that failed 3× and need human review. The Ralph Loop will skip these.

---

## Template

### F<X.Y> — [Feature Name]

**Failed at iteration:** N

**Reason:**
Why did it fail 3×?

**Last error:**
Copy of the last error message or test failure.

**Human review needed:**
What specific decision or intervention is required?

---

<!-- F0.3 resolved iter 7 — schema applied to Supabase, /health connected. See FEATURE_BACKLOG. -->
<!-- F0.5 resolved iter 6 — Dart client at packages/openapi/. See ADR-007. -->

---

### F0.4 — EXIF spike, iOS half

**Failed at iteration:** N/A (deferred, not failed)

**Reason:**
Same root cause as F0.1's iOS half: iOS apps cannot be built or deployed from WSL2 (no Xcode, no CocoaPods, no macOS). The spike's iOS acceptance criteria — JPEG/HEIC pick with "Full Access" permission, HEIC verified on real device — cannot run without a macOS host. The Android half of F0.4 is in progress (see FEATURE_BACKLOG iter 8 entry).

**Last error:**
N/A — environment limitation, not a code failure.

**Human review needed:**
Defer until a macOS contributor or macOS CI runner is available (F0.6 scope candidate). When that lands, run the photo_manager-based spike on iOS, verify HEIC pickup and EXIF GPS extraction, then close the iOS half and write ADR-009 (formal EXIF spike outcome ADR).

---
