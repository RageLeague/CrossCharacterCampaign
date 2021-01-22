# Cross Character Campaign

A mod that allows you to play as other characters in Griftlands.

Version: 1.4.0
Workshop ID: 2219176890
Alias(Used for mod dependency): CrossCharacterCampaign

Author: RageLeague

Supported Languages: English, 简体中文, 繁體中文.

Supported Characters:

* Sal (Base game)
* Rook (Base game)
* Smith (Base game)
* PC Shel (Shel's Adventure - https://steamcommunity.com/sharedfiles/filedetails/?id=2217590179)
* PC Arint (Arint's Last Day - https://steamcommunity.com/sharedfiles/filedetails/?id=2256085147)
* PC Kashio (Rise of Kashio - https://steamcommunity.com/sharedfiles/filedetails/?id=2266976421)

## How does it work?

This mod adds mutators that allows you to play as other characters in Griftlands.

You can also set the outfit of each character and apply the mutator. Then you can make that character wear the old character's outfit.

This simply allows you to play a character(with their unique deck, grafts, and mechanics) in other character's story. It doesn't change any quests to reflect on the changes. Sometimes picking an option that doesn't make sense will cause the game to crash, so don't trade your non-existing lucky coin with Krog's weighted coin.

This mod also adds another mutator that allows coin grafts to show up as a generic graft reward. Only useful when playing as Rook, obviously.

This mod adds an additional mutator that will randomly select a character. The characters selected are from all player backgrounds(even modded ones that doesn't have a mutator defined), and the randomization is rigged so that you will not get too many streaks in a row.

This mod is compatible with most other mods, however if it is not compatible with some mods, please let me know!

**Notice! Since all versions of Griftlands now complies with the new modding system, there is no need for the old mod. I'll leave the old branch up, just in case, but you should really update your mod if you want it to work.**

## How to install?

### Directly from GitHub

With the official mod update, you can read about how to set up mods at https://forums.kleientertainment.com/forums/topic/116914-early-mod-support/.

1. Find `[user]/AppData/Roaming/Klei/Griftlands/` folder on your computer, or `[user]/AppData/Roaming/Klei/Griftlands_testing/` if you're on experimental. Find the folder with all the autogenerated files, log.txt, and `saves` directory. If you are on Steam, open the folder that starts with `steam-`. If you are on Epic, open the folder that contains only hexadecimal code.
2. Create a new folder called `mods` if you haven't already.
3. Clone this repository into that folder.
4. The `modinit.lua` file should be under `.../mods/[insert_repo_name_here]`.
5. Volia! Now the mod should work.

### Steam workshop

With the new official workshop support, you can directly install mods from steam workshop. You can read about it at https://forums.kleientertainment.com/forums/topic/121426-steam-workshop-beta/ and https://forums.kleientertainment.com/forums/topic/121488-example-mods/.

1. Subscribe this item.
2. Enable it in-game.
3. Volia!

## Translators wanted!

This mod is designed around the game's localization systems, and it would be a shame to let it go to waste. If you want to help me out by adding a localization file for a language of your choice, then go for it! Feel free to contact me about this topic.

To generate a .pot file for this mod, do the following:

1. If debug mode is not enabled first, enable it. (Please reference https://forums.kleientertainment.com/forums/topic/121803-your-first-mod/ for more details)
2. Run the game while this mod is active.
3. Press F10 to open the debug localization screen.
4. Select the mod ID of this mod. If you installed it with steam workshop, it should be the workshop ID. If you installed it via GitHub, it should be the folder name of the mod folder.
5. Press Export Localization. The localization file should be found in the same folder as your game files(NOT your save files!).

A .pot file should also be found in the folders of this mod, if you can find it. It is NOT guaranteed to be up to date.

## Notice for other modders

Since update 1.2.0, you can add a mutator for a character you added. A helper function `AddCharacterOverrideMutator(id, graft)` is added to the global space that allows you to easily add a character override mutator. If you're not interested, you should skip this section since it's quite boring.

The function `AddCharacterOverrideMutator(id, graft)` accepts two parameters. `id` is the ID used to identify your mutator graft, and `graft` is a table that contains your mutator information. It has the same behaviour as `Content.AddMutatorGraft(id, graft)` if used on a normal mutator, but does different things if it is a character mutator.

A "character mutator" modifies the current player character if selected. To set the character selected, set the field `override_character` to your player background ID.

When the function is called on a character mutator, it does a few things:

1. It tries to figure out the mod ID of the character background the mutator has. If it finds one, it assigns the mod ID to the field `character_from_mod` for determining mod requirements at the start of a new game.
2. It adds the definition to Content.
3. It tracks it to a list of character mutators, and change the field `exclusion_ids` of all character mutators to include all other character mutators, since it doesn't make sense for the player to be able to select two character mutators at once. Note any original `exclusion_ids` will be overwritten, so don't define a `exclusion_ids` field.

For example, to add Sal's character mutator, this is the code that should be run.

```lua
AddCharacterOverrideMutator("play_as_sal",{
    name = "Play As Sal",
    desc = "Play through this campaign as Sal",
    img = engine.asset.Texture("[path to file]", true),
    img_path = "[path to file]",
    override_character = "SAL",
})
```

Note: The function `AddCharacterOverrideMutator(id, graft)` is added to global space during the registration of the mod. You can probably call it during OnLoad. However, I'm not sure whether defining this function during registration will break anything, so it might be safer to call it during one level of PostLoad(the returned function from your OnLoad function).

## CHANGELOG

### 1.4.0

* Added two new modded characters: PC Arint (https://steamcommunity.com/sharedfiles/filedetails/?id=2256085147) and PC Kashio (https://steamcommunity.com/sharedfiles/filedetails/?id=2266976421).
* Added a system that allows one mutator trying to match multiple backgrounds, in case the dev of the PC Arint mod decides for some reason to change the name of the player background.

### 1.3.2

* Added a random character mutator that will randomly select a character. The characters selected are from all player backgrounds(even modded ones that doesn't have a mutator defined), and the randomization is rigged so that you will not get too many streaks in a row.
* Updated strings for Chinese Simplified and Traditional.

### 1.3.1

* Added a nil-check for mutators selected because it's possible to start a game with invalid mutators, and that would crash the game.

### 1.3.0

* Make this mod even more compatible with further mods! It's probably because the "further" mods part is my mod, and I need to fix how I implemented the character replacement function.
* Now instead of rewriting the entire function, it uses the old function, but creates a player character beforehand if a character mutator is selected.
* Although this update is a minor fix, the actual fix done to it is extremely major, so the minor version number increased. This may or may not break some things, so please let me know if this update broke your mod so I can fix it.

### 1.2.0

* Support for other mods! Other mods can add their custom characters as a mutator for this mod.
* Added a new mutator if you are playing with Shel's Adventure, Klei's official mod. (https://steamcommunity.com/sharedfiles/filedetails/?id=2217590179)
* Various other optimizations and safeguards.

### 1.1.1

* Minor update that makes the localization loading part in the OnPreLoad function.

### 1.1.0

* Workshop support!
* Added preview icon.
* Made it compatible with the latest experimental version(version 429468). This means that the old version probably won't work anymore.

### 1.0.3

* Remove an unnecessary dependency, as it causes problems in Experimental.
* Fix bug where playing a game without mutators unlocked will cause the game to crash.
* Changed "Japanese" "localization" to Simplified Chinese localization, since there's now actually Chinese in the game. Also updated the translation for Grafts.
* Add Traditional Chinese localization. They are close enough anyways, might as well do it.

### 1.0.2

* Adds "Japanese" "localization".
* Adds icons to the new mutators.

### 1.0.1

* Changed all Sal's brawl grafts to the general series, so other characters can use them.

### 1.0.0

* A new mutator called "Rewardable Coins". Enable this mutator to allow Rook to acquire non-default coin outside of his campaign! Coins will show up as a generic graft reward sometimes.
* Update the UI of pick graft screen so that coin grafts will show up as correct color and correct description.(Still incorrect icon right now, but there's little I can do about it.)
