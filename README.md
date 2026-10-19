# settlers2_saveeditor
Save Editor for Settlers 2 Gold Edition

Settlers II Gold Resource Editor
================================

This is a small PowerShell editor for the original Settlers II Gold Edition
(v1.51) TRANSxxx.DAT save files.

It edits the 61 two-byte inventory values belonging to your own HQ. The first
31 are goods/resources; the remaining entries are settlers, soldiers, and
animals.

How to use
----------
1. Make a backup of your entire Settlers II SAVE folder.
2. Double-click Run_Resource_Editor.cmd.
3. Click "Open TRANSxxx.DAT" and select the TRANS file for your save slot.
4. Select a resource and use "Set selected" to change it.
5. "Set goods to value" changes the first 31 goods only and leaves settlers
   and animals alone.
6. Click "Save changes".

The editor creates a .bak copy of the original TRANS file before it writes
changes. It does not change the file size or insert/remove bytes.

Important
---------
This version edits the inventory associated with the player's HQ. It does
not yet automatically redistribute stock between multiple warehouses.
Maximum value is 65535 because the game's inventory fields are unsigned
16-bit values.

The resource layout was verified against two real Settlers II Gold saves:
logs 12 -> 11, planks 27 -> 28, stone 186 -> 189.
