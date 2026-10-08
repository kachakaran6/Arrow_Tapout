# Motion, Audio, Haptics, and Accessibility

## Arrow exit animation
- Animate the arrow along its intended direction, not by shrinking it in place.
- Use a short, polished ease-in/ease-out curve; tune timing on real devices.
- Fade subtly only near the end of travel.
- Keep stroke width and path continuity stable.
- Other arrows remain stationary.
- Lock that arrow against repeat taps while its exit is pending.
- Remove it from engine state exactly once when animation completes.
- If reduced motion is enabled, use a shorter translation/fade or immediate state change with clear feedback.

## Blocked move
- Brief 100–160 ms directional nudge or restrained path emphasis.
- Optional light haptic tick if enabled and supported.
- No modal dialog, harsh red flash, loud sound, or repeated vibration.
- Rate-limit haptic feedback so rapid tapping cannot spam it.

## Level completion
- A quiet transition and concise success message.
- Do not rely on animation alone to communicate completion.
- Respect reduced motion and sound settings.
- Avoid confetti, screen shake, glow, or forced delay before Next.

## Audio
- Sound is optional and off/on state persists locally.
- Use small, locally bundled sound assets with appropriate licenses or generate simple non-musical UI tones.
- Never stream audio.
- Handle audio interruption and lifecycle changes.
- Do not play a sound for every redraw or pointer event.

## Accessibility
- Semantic labels for arrows should include direction and whether the exit is blocked if that state can be determined without excessive cost.
- Provide accessible labels for controls.
- Maintain adequate contrast in all five themes.
- Do not use color as the only signal for locked/completed/blocked state.
- Support large text and screen readers.
- Provide a logical focus order.
- Ensure critical controls have sufficiently large hit targets.
- Test with TalkBack, large text, and Android accessibility settings.
- Keep hit testing tolerant without allowing adjacent arrows to become impossible to select.
