# Value proposition

## Value proposition canvas

### User jobs

- Prepare chosen content.
- Hand off the device.
- Avoid accidental interaction.
- Recover control securely.
- Understand the boundary between in-app blocking and device-level containment.

### Pains

- A child pauses or navigates away from content.
- The caregiver repeatedly interrupts another activity.
- Guided Access is powerful but not always configured or remembered.
- A hidden unlock can become a lockout if poorly communicated.
- “Parental controls” language can imply content or safety guarantees that do not exist.

### Gains

- Fewer corrective device take-backs.
- A calm, predictable handoff ritual.
- Reuse of web and local content the caregiver already selected.
- A deliberate adult-only exit.
- Honest explanation of when protection is incomplete.

### Pain relievers and gain creators

| Mechanism | Value | Evidence/status |
|---|---|---|
| Touch-blocking overlay | Stops touches reaching in-app content | Implemented in [`BabyLock/ChildMode/ChildModeController.swift`](../../BabyLock/ChildMode/ChildModeController.swift) |
| Lock enabled only with content | Reduces empty handoffs | Implemented in [`BabyLock/Parent/ParentView.swift`](../../BabyLock/Parent/ParentView.swift) |
| Center-hold + passcode | Separates adult recovery from visible child controls | Implemented; gesture geometry has unit tests |
| Share extension URL path | Reduces switching cost from web discovery | Configured in [`project.yml`](../../project.yml); URL validation is unit-testable |
| Guided Access education | Makes platform limitation actionable | Implemented in settings; comprehension unvalidated |

## Alternatives and differentiation

BabyLock's differentiation is not stronger OS control than Apple. It is a purpose-built sequence around the content handoff: familiar content in, inert viewing, private recovery, and explicit Guided Access guidance. Compared with a kids-content app, it avoids a new catalog. Compared with Guided Access alone, it packages the setup and recovery around this specific moment. Compared with manual correction, it acts before disruption.

## Positioning statement

For caregivers of babies and toddlers who occasionally hand over an iPhone or iPad with selected media, BabyLock is a focused in-app touch shield that turns prepared content into an inert viewing surface and provides deliberate parent recovery. Unlike content platforms or broad parental-control suites, it keeps content choice with the caregiver and explicitly relies on Apple Guided Access for full device containment.

## Benefit ladder

| Feature | Functional benefit | Emotional benefit | Higher-order value |
|---|---|---|---|
| Browser/local media inputs | Keep using selected content | Less setup anxiety | Preserve caregiver agency |
| One lock action | Enter child mode quickly | Confidence at handoff | Attention returns to the real-world task |
| Touch overlay | Prevent in-app disruption | Less frustration | More predictable shared moments |
| Passcode recovery | Authorized return to parent mode | Reduced lockout fear | Trustworthy reversibility |
| Guided Access status/tutorial | Clarify protection boundary | Honest confidence | Safety claims match reality |

## Proof and assumptions

**Proof available:** source structure, app configuration, unit tests for gesture boundaries, URL-scheme tests, and Keychain implementation in [`BabyLock/Shared/PasscodeStore.swift`](../../BabyLock/Shared/PasscodeStore.swift).

**Not proven:** caregiver demand, reduction in interruptions, child resistance, accessibility, battery impact, compatibility across media sites, secure threat model, or willingness to complete Guided Access setup.

The value proposition should advance only when usability evidence confirms that caregivers can lock, interpret protection status, and recover under realistic distraction.
