# Roadmap and success metrics

## Outcome framing

Success is not downloads or time spent. It is a trustworthy handoff that reduces caregiver intervention while preserving rapid, authorized recovery and accurate understanding of platform limits.

## Now: prove safe comprehensibility

- Test first-use understanding of app-only protection versus Guided Access.
- Validate lock and unlock under distraction, motion, orientation changes, and one-handed use.
- Define a content-ready state and explicit load failures.
- Audit VoiceOver, Dynamic Type, contrast, and motor-access implications.
- Create a manual supported-source matrix for browser, share extension, video, and photo.

**Exit criterion:** target caregivers can prepare, lock, explain the protection boundary, and recover without moderator rescue. Set numeric thresholds only after a pilot establishes distributions.

## Next: measure the core outcome

- Add privacy-preserving, local session counters for setup duration, lock attempts, unlock attempts, and abnormal exits.
- Ask for optional post-session feedback: “Did you need to take the device back?”
- Test a pre-lock Guided Access checkpoint against the current post-unlock tutorial.
- Add explicit retry and fallback paths for failed web loads.
- Evaluate idle-session battery safeguards without interrupting active playback.

## Later: expand only after evidence

- Guided Access deep-link or setup affordances that remain within public iOS capabilities.
- Caregiver-configurable accessible unlock alternatives, threat-modeled against accidental activation.
- A curated compatibility guide—not content certification.
- iPad-specific layout refinements.
- Release hardening, privacy documentation, and App Store readiness.

Remote monitoring, accounts, content recommendations, and OS-wide controls remain out of scope unless research reveals a stronger adjacent job.

## Hypotheses

| Hypothesis | Signal | Falsifier |
|---|---|---|
| One explicit lock action reduces recovery burden | Lower intervention time than normal playback | Setup/unlock overhead exceeds time saved |
| Pre-lock protection copy improves safe understanding | More users correctly identify app-only limits | Comprehension unchanged or abandonment rises materially |
| Hidden center hold balances obscurity and recovery | Low accidental triggers and bounded adult completion time | Adults repeatedly fail or children discover it quickly |
| Existing content inputs reduce adoption friction | High completion from content-ready to lock | Browser/share incompatibility dominates |

## Metrics

### Leading

- Content-load success rate by source type.
- Median content-ready-to-lock time.
- Lock-attempt completion rate.
- Guided Access status comprehension score in usability testing.
- Unlock attempt count and completion time.

### Lagging

- Handoffs with no caregiver intervention.
- Recovery seconds avoided versus the participant's normal method.
- Repeat use across distinct days, if measured with consent.
- Caregiver-reported confidence after use.

### Guardrails

- Unexpected app-exit rate during child mode.
- Lockout/force-quit/restart rate.
- Sessions where user believed device-level containment was active when it was not.
- Battery/thermal incidents during extended sessions.
- Accessibility task-failure rate.

No current values are claimed.

## Instrumentation plan

Use event names without content URLs, titles, photos, passcodes, or child identifiers:

`setup_started`, `setup_completed`, `content_load_started(source_type)`, `content_ready`, `content_load_failed(error_class)`, `lock_started`, `child_mode_entered(guided_access_active)`, `unlock_gesture_started`, `unlock_gesture_reset(reason)`, `unlock_succeeded`, `child_mode_exited(exit_class)`.

Keep raw events on-device by default. Any export requires explicit consent, retention limits, and a documented deletion path.

## Experiment backlog

1. Post-unlock tutorial vs pre-lock protection checkpoint.
2. Text-only vs status-card explanation of Guided Access.
3. Center-hold duration/target tuning across caregiver motor contexts.
4. Share-extension-first vs in-app-browser-first onboarding.
5. Automatic stale-session warning vs no warning for battery protection.

## Risks and dependencies

- iOS gesture and app-containment constraints.
- Third-party web content compatibility.
- Keychain and recovery behavior across reinstall/device states.
- Caregiver accessibility and passcode recall.
- Privacy review before telemetry leaves the device.
- Clear legal/product language that avoids safety guarantees.

## Definition of success

Advance toward release only when evidence shows the core flow saves net caregiver effort, adults can reliably recover, accidental interaction is materially reduced, and users accurately understand that full device containment depends on Guided Access.
