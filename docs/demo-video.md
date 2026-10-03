# Demo video plan (about 2.5 minutes)

The order follows the submission brief: problem, a couple finds and fixes a clash, the group board with the budget, a seated participant, the vendor link, and the same engine on another event. Narration in English. No music, or royalty-free music only.

Honesty rules for the recording:

- The demo events are illustrations. Their banner ("Demo event: the people and renders are illustrations") stays visible; say it once out loud.
- Show at least one **live** YouCam render of a consenting adult, and say that it is live. It costs about 2 units for an outfit, plus 1 each for a lip and a hair color.
- Do not quote a number that has no source. Put a sourced figure where the script says *[figure]*, or drop the sentence.
- The seated success rate is shown only after the inclusion evaluation has been run (`npm run kill-tests` in `api/`, then the inclusion page). Until then, show the page with "not measured yet".

## Shots

| Time | Screen | Action | Narration |
| --- | --- | --- | --- |
| 0:00 | Landing page | Let the headline and the harmony showcase play. | "Every virtual try-on is built for one person. But at a prom, a play or a wedding, what matters is how people look next to each other. *[figure on what Bulgarian families spend on the prom]*." |
| 0:12 | Landing page | Click **Prom demo**. | "Wearmony is group try-on. This is a demo prom with illustrated people." |
| 0:18 | Together tab | The demo makes you Sofia's partner, in a sand tie. The near-miss card glows. | "I'm going with Sofia, and I picked a sand tie. Next to her champagne dress it's a near-miss: close, but not the same shade. In photos that reads as a mistake." |
| 0:32 | Together tab, How to fix it | Point at the cards, then **Switch to this** on the champagne tie. The celebration appears. | "Wearmony tries every item in the event catalogue with the same color math and keeps only real fixes. The champagne tie matches her dress exactly, at the same price, and the group score jumps. One tap, and the clash is gone." |
| 0:48 | My look tab | **Try it on** on a live event with a real photo. | "The preview is a live YouCam render: AI Clothes for the outfit, Makeup VTO for the lip color, AI Hair Color for the hair. Each step is cached, so the same photo and item never cost twice." |
| 1:05 | Group tab | Scroll past the stats, the budget split and readiness. | "The organizer sees everyone: who has rendered, the weakest color pair, the budget per person and in total, and who still needs a photo or a lock." |
| 1:20 | Group photo | Open it, switch backdrops, **Save image**. | "And the whole group in one frame, partners together, with the harmony score. The image keeps the label that says what is simulated." |
| 1:35 | Group tab, Elena's card, then the Inclusion page | Point at the seated badge, then the results table. | "Try-on is usually tested on standing models. Elena is seated. We measure how well it works for seated photos and publish the numbers: *[measured rate, or 'not measured yet']*." |
| 1:52 | Invite tab, then the vendor page | Create a hairdresser link, open it on a phone. | "A hairdresser gets a read-only link that expires: the chosen hair color and the before photo. No account." |
| 2:05 | Landing, **Theatre cast demo**, then the group photo and harmony map | Stage backdrop; Romeo and Mercutio's teal line pulses. | "Same engine, another event: a school play. Two doublets in almost the same teal would look like a costume mistake on stage." |
| 2:20 | Landing page | Language menu: English to Bulgarian. | "Wearmony works on the web and Android, in English and Bulgarian. Try it on together." |

## Before recording

1. Run the backend with `YOUCAM_MODE=live` for the live shot, or record that shot separately on the deployed app.
2. Open the demos once before recording, so their images are cached and load instantly.
3. Record the phone shots on an Android phone with the APK, or in Chrome device mode at 412 × 915.
