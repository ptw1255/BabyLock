# BabyLock product portfolio

## Thesis

BabyLock explores a narrow but high-friction handoff: a caregiver has already chosen appropriate media, but a toddler's incidental touches repeatedly interrupt it. The product thesis is not “more parental controls.” It is that a fast, legible transition from **prepare** to **inert viewing** can reduce caregiver intervention while retaining a deliberate, passcode-gated way back. The repository demonstrates that interaction model; it does not prove demand, safety outcomes, or production readiness.

## Artifact map

| Artifact | Decision it supports |
|---|---|
| [Product brief](product-brief.md) | Why this problem, for whom, and what is intentionally excluded |
| [Users and JTBD](users-and-jtbd.md) | User contexts, progress sought, stories, and acceptance signals |
| [Value proposition](value-proposition.md) | Alternatives, differentiated value, and proof gaps |
| [Pain points and opportunity costs](pain-points-and-opportunity-costs.md) | Consequences, proxy formulas, risks, and priorities |
| [Wireframes](wireframes.md) | Core parent-to-child flow plus loading, empty, and failure states |
| [Roadmap and success metrics](roadmap-and-success-metrics.md) | Evidence-gated sequencing, instrumentation, and experiments |

## Evidence and status legend

- **Evidence** — directly observable in repository code, tests, or configuration; cited with a repo-relative path.
- **Inference** — a product interpretation consistent with evidence but not demonstrated by research.
- **Assumption** — an unvalidated belief requiring discovery or measurement.
- **Hypothesis** — a falsifiable proposed change or outcome; not a shipped capability.

## Evidence snapshot

- **Evidence:** Web URLs, local video, and local photo are represented as content sources in [`BabyLock/App/AppState.swift`](../../BabyLock/App/AppState.swift).
- **Evidence:** Parent mode exposes browser, media picker, settings, and lock actions in [`BabyLock/Parent/ParentView.swift`](../../BabyLock/Parent/ParentView.swift).
- **Evidence:** Child mode hides system chrome, defers edge gestures, disables idle sleep, overlays content, and invokes passcode entry after the custom gesture in [`BabyLock/ChildMode/ChildModeController.swift`](../../BabyLock/ChildMode/ChildModeController.swift).
- **Evidence:** Guided Access is explicitly presented as necessary for complete app containment in [`BabyLock/Parent/SettingsView.swift`](../../BabyLock/Parent/SettingsView.swift).
- **Evidence:** Center-region and movement-threshold behavior has unit coverage in [`BabyLockTests/UnlockGestureTests.swift`](../../BabyLockTests/UnlockGestureTests.swift).
- **Assumption:** Caregivers can learn and reliably perform the hidden center-hold gesture under real-world conditions.
