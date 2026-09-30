# Wearmony

**Try it on together.**

Wearmony is a group virtual try-on: everyone attending an event (a prom, a play, a wedding, a family photo) tries on an outfit, makeup and hair color on their own photo, and the group sees itself together in one frame, with a color-harmony check and a shared budget, before anyone spends money.

Built for the *YouCam API Skin AI & eCommerce VTO Hackathon*.

> Status: early development. Setup instructions, results and screenshots will be added as each part lands.

## Problem

Every virtual try-on product is built for one person, but event outfits are decided together. At Bulgarian high-school proms, couples and friend groups coordinate colors by trading screenshots and often discover clashes on the night itself. Try-on is also usually tested on standing models; Wearmony is designed to work for seated users too, and to measure and publish how well it does.

## What it does

- **Organizer** creates an event, invites people by link or code, and sees the group board, the budget and harmony warnings.
- **Participant** uploads one photo, tries on items from the event catalogue, sees themselves next to their partner or group, and locks a final look.
- **Vendor** (for example a hairdresser) gets a read-only, expiring link with the chosen look.

## Repository layout

```
app/        Flutter client (web + Android)
api/        Serverless backend (TypeScript on Vercel)
  youcam/   the only module that talks to the YouCam API
  harmony/  color extraction, CIEDE2000, rule thresholds
  ledger/   API unit budget
fixtures/   recorded API responses used by tests
eval/       inclusion evaluation scripts and results
docs/       methods, screenshots, README assets
```

## Limits and honesty

Renders are a visual preview, not a fit guarantee. Any precomputed or simulated content in the app or the demo is labeled as such.

## Privacy

Participants must be adults and give explicit consent before uploading a photo. Photos are private to the event; organizers can delete an event with all its media, and participants can delete their own data at any time.

## License

[MIT](LICENSE)
