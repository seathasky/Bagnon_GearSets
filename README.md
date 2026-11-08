# Bagnon Gear Sets

By Seathasky.

A companion addon for Bagnon 12.1.8 on Retail and Forever. The manifest supports
Retail interface 120105 and Forever interface 16001 (the installed client builds).
Equipment-set membership supports both the namespaced and legacy global API.
Each client requires Bagnon and this addon in its own Interface/AddOns folder.

Save your gear in WoW's Equipment Manager, then open Bagnon. A Gear Sets title
appears above the gear sections. Gear appears in
alphabetical sections labeled `Gearset: Name`, with gold set-name
labels across the top of each icon. Remaining items and empty slots follow in
Bag Contents (or Bank Contents in the bank view).
The equipped reagent bag gets its own Reagent Bag section, including its empty
slots, even when no gear sets are present. This uses actual bag slots; reagents
stored in regular bags remain in Bag Contents. Reagent and gear sections have
independent toggles and follow the same live-view restrictions.
Long names are clipped to the available width; WoW's normal item tooltip remains
available. Shared pieces appear once in a section labeled with all their sets.

The addon only rearranges the display. It does not move items between bag slots.
Bagnon's item actions, tooltips, search, and sidebar filters remain in use.
Visible items retain their bag/slot order within each section. Section mode
supersedes bag breaks. Labels also work in the live Bagnon bank, when installed.
Cached inventories/banks use Bagnon's normal display without set labels because
the live equipment-set API cannot identify cached items safely. Transposed grids
use the normal layout with labels. Sections stay enabled during combat using
Bagnon's existing item buttons, including when bags refresh or reopen.

## Controls

Open **Settings > AddOns > Bagnon > Gear Sets** for Separate Gear Sets,
Separate Reagent Bag, and Show Equipment Set Labels. All three default to on
and are saved account-wide. Changes apply immediately to open bags.

- `/bgs` shows the current settings.
- `/bgs sections` toggles named sections.
- `/bgs labels` toggles item labels (for an MABF-style labels-only setup, disable sections).
- `/bgs reagents` toggles the reagent bag section independently.

If MABF or another addon
also draws set names, disable one addon's labels to prevent overlapping text.

## In-game verification

Restart WoW if the addon folder is new, then enable Bagnon Gear Sets. Check:

1. Two saved sets, an item shared by both, and an unrelated duplicate item.
2. Moving gear, equipping a set, and saving, renaming, or deleting a set.
3. Search, sidebar filters, reverse slot order, column count, and item scale.
4. Bank access, cached character views, entering/leaving combat, reopening bags
   and refreshing contents during combat, and all three toggles.

The integration uses Bagnon's internal ItemGroup and ContainerItem classes.
Future Bagnon changes may require updating the hooks. Verify changes in both
game clients before publishing a release.

## Releases

Pushing a version tag such as `v1.0.0` runs the GitHub Actions release workflow.
BigWigs Packager builds a ZIP with the top-level folder `Bagnon_GearSets` and
publishes a GitHub release. Editor files and tests are excluded from the ZIP.

For CurseForge publishing, configure the repository's Actions secret
`CF_API_KEY` with an author upload token and its Actions variable
`CURSEFORGE_PROJECT_ID` with this addon's numeric project ID. Until the project
ID is configured, the workflow publishes only to GitHub. The CurseForge project
must be created separately; its ID must not be copied from another addon.
