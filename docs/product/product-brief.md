# Product brief

## WHY: problem and stakes

A caregiver who hands a phone to a baby or toddler often wants one bounded outcome: chosen content keeps playing long enough to cover a short transition, meal, or wait. Normal media interfaces optimize for interaction. For a child who cannot distinguish controls from content, every tap can pause, navigate, expose another app, or summon system UI. The caregiver then becomes an error-recovery loop.

**Inference:** The important cost is not a single accidental tap; it is repeated attention switching at moments when the caregiver chose media because attention was already scarce. The design spec frames this exact interruption problem in [`docs/specs/2026-04-13-babylock-ios-app-design.md`](../specs/2026-04-13-babylock-ios-app-design.md).

## Target user and context

- **Primary user:** caregiver of a child roughly 0–3 who controls setup, content choice, locking, and unlocking.
- **Beneficiary:** child who receives uninterrupted viewing but is not expected to understand the UI.
- **Context:** one shared iPhone or iPad, chosen media already available, short setup window, noisy or mobile environment, and one-handed operation likely.
- **Negative user:** someone seeking remote monitoring, time limits, content curation, OS-wide parental controls, or a substitute for supervision. BabyLock does not implement those jobs.

These segments are hypotheses, not research findings.

## Current alternatives

| Alternative | Why it works | Residual friction |
|---|---|---|
| Hold the device for the child | No setup | Consumes caregiver attention and a hand |
| Repeatedly restore playback | Uses familiar apps | Reactive; interruption has already happened |
| Apple Guided Access alone | OS-level containment | Setup and touch-disable controls can be hard to recall in the moment |
| Downloaded kids-content app | Purpose-built UI | Requires changing content source and trusting its catalog |
| Do not hand over the device | Avoids digital risk | Gives up the situational benefit the caregiver sought |

## Opportunity

Own the **last meter of the handoff**: load the caregiver's chosen web or local content, confirm it is ready, make touches inert, and provide a parent-only recovery path. This is narrower than parental control and therefore potentially easier to understand.

## Product thesis

If a caregiver can move from selected content to an inert screen in one obvious action—and can confidently recover with a private gesture plus passcode—then incidental-touch interruptions should fall without requiring a new content ecosystem.

Why this matters: confidence comes from predictable boundaries, not feature volume. The product should make its protection level explicit because [`BabyLock/Parent/SettingsView.swift`](../../BabyLock/Parent/SettingsView.swift) confirms that full device containment requires Guided Access.

## WHAT: current experience

1. First launch requires passcode setup through the `hasCompletedSetup` gate in [`BabyLock/App/AppState.swift`](../../BabyLock/App/AppState.swift).
2. A caregiver loads a URL in the in-app browser, selects local media, or arrives through the share-extension URL scheme configured in [`project.yml`](../../project.yml).
3. Lock becomes available when `contentSource.hasContent` is true in [`BabyLock/Parent/ParentView.swift`](../../BabyLock/Parent/ParentView.swift).
4. Full-screen child mode places a touch-blocking overlay above web, video, or photo content in [`BabyLock/ChildMode/ChildModeController.swift`](../../BabyLock/ChildMode/ChildModeController.swift).
5. A center hold progresses to passcode entry; correct verification returns to parent mode.

## Scope

- Content handoff from browser/share URL or local media.
- In-app touch interception and immersive presentation.
- Parent unlock gesture and passcode.
- Guided Access status and setup education.

## Non-goals

- Content recommendation, filtering, moderation, or age certification.
- Screen-time policy, remote administration, monitoring, or accounts.
- Guaranteed OS-level kiosk security without Guided Access or MDM.
- Claims that the child cannot exit the app under every condition.

## Product principles

1. **Protection claims must match platform reality.** False confidence is worse than setup friction.
2. **Parent action should be visible; child controls should not.** Lock is explicit, unlock is deliberately obscure.
3. **Recoverability outranks cleverness.** Every failure state must explain the next safe action.
4. **Content remains the caregiver's decision.** The app is a shield, not a catalog.
5. **Local by default.** No network analytics are evident; preserve that privacy posture unless consent and value are established.

## Evidence gaps

The repository has implementation and unit-test evidence, but no usability sessions, field observations, accessibility audit, App Store readiness, supported-site matrix, battery testing, or observed outcome metrics. The design document describes intent; only code and tests cited above should be treated as implemented proof.
