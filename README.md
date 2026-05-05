# Sentry
**A streamlined, zero-dependency tactical environment tracker for Achaea and Mudlet.**

Sentry is a modern combat and situational awareness UI. It natively captures Achaea's GMCP data and organizes the room into a clean, highly readable interface. By filtering out the noise of standard room descriptions, Sentry ensures you never miss a dropped item, an active totem, or a hostile environmental effect. 

Unlike older trackers, Sentry relies strictly on Mudlet's native Geyser layout manager, requiring no external packages or dependencies.

---
## Screenshots
<img width="297" height="317" alt="image" src="https://github.com/user-attachments/assets/f738f2cd-eb73-4a5c-a128-e0c3c67ee806" />

---
## Features

* **Zero Bloat:** Single-script architecture. No reliance on legacy packages.
* **Smart Sorting:** Automatically separates generic clothing and static furniture from tactically important items (like dropped commodities, vials, and weapons). 
* **Interactive Targeting:** Provides compact `[T|P]` (Target/Probe) and `[G|P]` (Get/Probe) clickable links directly in the UI for rapid interaction.
* **Silent Probing:** Automatically probes walls, totems, and sigils in the background, cleanly extracting their data without spamming your main window.
* **Hazard Tracking:** Routes totems, sigils, fires, and vibrations to a dedicated "EFFECTS" category. Automatically detects and highlights flame sigil traps.
* **Glance Mode:** Intelligently recognizes when you use the `glance` command, appending a `(Glanced)` tag to the UI and safely disabling interaction links.
* **Loyal Tracking:** Use the `sentry loyals` command to instantly track and highlight your loyal companions in cyan.

---

## Installation

1. Download the `Sentry.mpackage` or import the `Sentry-Core.lua` script directly into your Mudlet Script Editor.
2. Save the script. The UI will instantly generate on the left side of your screen.
3. Edit the `Sentry.config` block at the top of the script to adjust your command prefixes, toggle visibility, and expand your furniture/clothing sorting dictionaries.

You can put the Geyser window anywhere. However, we recommend going into Preferences > Main Display in Mudlet and adding a Display Border in which to contain this package so it never overlaps your main game text!

---

## In-Game Commands

Sentry includes a few lightweight commands you can run directly from the Achaea input line:

* `sentry toggle`: Hides or shows the Sentry UI window. 
* `sentry loyals`: Manually updates your tracked loyal companions (also automatically updates on login).
