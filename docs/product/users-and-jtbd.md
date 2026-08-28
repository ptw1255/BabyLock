# Users and jobs to be done

## Personas

### Primary: time-constrained caregiver

Controls the device and content. Needs a dependable handoff while attention is divided. Success is “I did not have to take the phone back,” not “I configured a sophisticated policy.”

### Secondary: co-caregiver

May inherit a device already configured by someone else. Needs protection status and recovery instructions to be learnable without compromising the hidden gesture.

### Beneficiary: pre-literate child

Consumes content and produces exploratory touches. No task should depend on reading, restraint, or understanding interface conventions.

### Negative personas

- A caregiver seeking content safety guarantees.
- An organization needing managed kiosk compliance.
- An older child intentionally trying to bypass controls.
- A household needing cross-device profiles or remote control.

The current local, single-device model and Guided Access dependency do not serve those needs.

## Contexts

| Situation | Constraint | Product implication |
|---|---|---|
| Restaurant or waiting room | Noise, social pressure, little setup time | Lock readiness must be obvious |
| Car or transit | Motion and intermittent caregiver access | Accidental unlock must be rare; recovery must be clear |
| Home chore | Caregiver moves away briefly | Protection level must not be overstated |
| Shared device | Adult needs rapid return to normal use | Unlock should be deliberate but bounded |

## Jobs

### Functional

- Keep selected content visible despite incidental touches.
- Prevent in-app controls from receiving touch input.
- Return control to an authorized adult.
- Understand whether Guided Access is active.

### Emotional

- Feel confident handing over an expensive, personal device.
- Avoid the frustration and embarrassment of repeated interruptions.
- Avoid fear that “locked” implies more protection than is actually active.

### Social

- Keep a shared situation calm without visibly wrestling with the phone.
- Let another caregiver use the flow without a lengthy explanation.

## JTBD statements

1. **When** I have chosen a video and need both hands for something else, **I want** to make the screen ignore accidental touches quickly, **so I can** finish the immediate task without repairing playback.
2. **When** I hand my phone to a toddler in public, **I want** a trustworthy indication of the protection level, **so I can** decide whether to add Guided Access before letting go.
3. **When** I need my phone back, **I want** a deliberate recovery sequence that the child is unlikely to trigger, **so I can** return to normal use without force-quitting.
4. **When** another caregiver uses my configured device, **I want** them to understand the lock prerequisites, **so I can** share the workflow without sharing unnecessary device access.
5. **When** content loading fails, **I want** to remain in parent mode with a clear correction, **so I do not** hand over a blank or falsely locked experience.

## User stories with acceptance signals

| Story | Acceptance signal |
|---|---|
| As a caregiver, I can lock only after content exists | Lock is disabled for `.none`, as implemented in [`BabyLock/Parent/ParentView.swift`](../../BabyLock/Parent/ParentView.swift) |
| As a caregiver, I can see whether Guided Access is active | Settings reports `UIAccessibility.isGuidedAccessEnabled` in [`BabyLock/Parent/SettingsView.swift`](../../BabyLock/Parent/SettingsView.swift) |
| As a caregiver, I can recover without an exposed button | Center hold shows subtle progress and then passcode entry |
| As a child, exploratory touches do not operate content | Overlay remains above the content view in child mode |
| As a caregiver, invalid shared URLs are rejected | URL parser accepts only `http`/`https` in [`BabyLock/Shared/URLSchemeHandler.swift`](../../BabyLock/Shared/URLSchemeHandler.swift) |

## Forces of progress

| Push of current situation | Pull of BabyLock | Anxiety | Habit |
|---|---|---|---|
| Repeated paused/exited media | One explicit lock action | “Can my child still leave the app?” | Using native media apps directly |
| Caregiver attention consumed | Hidden adult recovery | “Will I lock myself out?” | Restoring playback manually |
| Guided Access setup friction | In-context tutorial | “Is this another parental-control suite?” | Avoiding setup until needed |

## Journey

1. **Trigger:** caregiver decides temporary media is useful.
2. **Prepare:** choose share URL, browse, or select local media.
3. **Assess:** verify content and protection status.
4. **Commit:** tap Lock; optionally start Guided Access.
5. **Trust:** child mode remains visually stable under touch.
6. **Recover:** adult holds center, enters passcode, and returns to parent mode.
7. **Reflect:** decide whether the handoff reduced intervention.

### Journey acceptance signals

- Setup-to-lock time can be measured without recording URLs or media.
- Accidental exits and parent interventions can be self-reported.
- Unlock completion, cancellation, and failed passcode counts can be measured locally and aggregated only with explicit consent.
- Caregivers can correctly explain “BabyLock alone” versus “BabyLock + Guided Access” after onboarding.
