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

### F0.1 — Flutter app scaffold

**Failed at iteration:** 1

**Reason:**
Flutter CLI not installed in system environment. The Ralph Loop cannot install Flutter SDK automatically.

**Last error:**
`flutter: command not found`

**Human review needed:**
Install Flutter SDK on this machine before re-attempting F0.1. For WSL+Windows development, follow Flutter's official installation guide for Windows and ensure WSL2 can access the Flutter installation.

---
