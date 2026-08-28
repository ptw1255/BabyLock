# Pain points and opportunity costs

No observed frequencies or outcomes are available. Ratings below are **research priorities**, not measured facts.

## Pain inventory

| Pain | Likely frequency | Potential severity | Consequence chain | Evidence |
|---|---|---:|---|---|
| Incidental touch interrupts media | Repeated within a handoff | Medium | touch → pause/navigation → child distress → caregiver intervention | Problem statement in [`docs/specs/2026-04-13-babylock-ios-app-design.md`](../specs/2026-04-13-babylock-ios-app-design.md) |
| Child exits the app | Occasional without Guided Access | High | exit → unrelated app/system access → urgent recovery | Platform limitation explicitly documented and surfaced in settings |
| Caregiver cannot unlock quickly | Rare but critical | High | failed gesture/passcode → prolonged lock → force-close/restart | Recovery path exists; field reliability unknown |
| Unsupported or failed web content | Depends on site | Medium | load failure → no content → abandoned handoff | Generic `WKWebView` path exists; no compatibility matrix |
| Protection level misunderstood | Once per setup/handoff | High | false confidence → unsupervised assumption → unexpected exit | Guided Access distinction exists but comprehension is untested |
| Screen remains awake too long | Per abandoned child-mode session | Medium | idle timer disabled → battery drain/heat | Implemented in child mode with reset on disappearance/deinit |

## Opportunity-cost formulas

These formulas define measurable proxies without inventing baselines:

- **Caregiver interruption cost per handoff**
  `interruption count × median recovery seconds`
- **Attention-switching burden per week**
  `handoffs per week × interruptions per handoff × recovery seconds`
- **Failed-handoff rate**
  `sessions abandoned before stable child mode / sessions where lock was attempted`
- **Protection-comprehension gap**
  `participants who believe app-only mode prevents exit / participants tested`
- **Unlock friction**
  `median seconds from first center touch to parent mode + failed gesture attempts`
- **Battery exposure**
  `child-mode minutes with no content playback or touch / total child-mode minutes`

The user's counterfactual matters: time saved by avoiding playback repair may be lost if setup plus unlock takes longer than manual correction. Net value per handoff can be proxied as:

`manual-recovery time avoided − (BabyLock setup time + incremental unlock time + Guided Access setup amortization)`

## Risks of inaction

- The prototype may remain technically interesting but impossible to evaluate because no privacy-preserving outcome instrumentation exists.
- Ambiguous “lock” language may create unsafe expectations.
- Compatibility failures may surface only in the highest-stress contexts.
- Accessibility barriers may exclude caregivers with motor, vision, or cognitive constraints.
- Unlock failure may outweigh all saved intervention time.

## Prioritization

| Priority | Why now | Next evidence |
|---|---|---|
| P0: protection-language comprehension | Affects safe use and trust | Moderated comprehension test: app-only vs Guided Access |
| P0: unlock reliability | Recovery failure is high severity | One-handed, moving, landscape/portrait usability sessions |
| P1: stable handoff funnel | Tests core value | Local counters for load → lock → unlock, with explicit consent before export |
| P1: content/load failure UX | Prevents false-ready states | Supported-source test matrix and error taxonomy |
| P2: battery and thermal safeguards | Important after core flow works | Long-session device tests and idle-content detection hypothesis |
| P2: share-flow discoverability | Reduces setup cost | Compare in-app browse vs share-extension completion time |

Priorities deliberately favor trust and reversibility over adding content sources.
