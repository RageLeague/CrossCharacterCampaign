-- MountModData( "CrossCharacterCampaign" )

-- local player_starts = require "content/player_starts"

local filepath = require "util/filepath"
local MUTATORS = 
{
    play_as_sal =
    {
        name = "Play As Sal",
        desc = "Play through this campaign as Sal",
        -- img_path = "negotiation/modifiers/grifter.tex",
        -- img = engine.asset.Texture( "negotiation/modifiers/grifter.tex", true ),
        override_character = "SAL",
        exclusion_ids = { "play_as_rook", "play_as_smith" },
    },
    play_as_rook =
    {
        name = "Play As Rook",
        desc = "Play through this campaign as Rook",
        override_character = "ROOK",
        exclusion_ids = { "play_as_sal", "play_as_smith" },
    },
    play_as_smith =
    {
        name = "Play As Smith",
        desc = "Play through this campaign as Smith",
        override_character = "SMITH",
        exclusion_ids = { "play_as_sal", "play_as_rook" },
    },
    rook_coin_reward =
    {
        name = "Rewardable Coins",
        desc = "Coins will show up as graft rewards(when applicable, which basically means playing as Rook)",
    },
}
local function OnNewGame(mod, game_state)
    if TheGame:GetGameState():GetOptions().mutators then
        for id, data in pairs(TheGame:GetGameState():GetOptions().mutators) do
            if MUTATORS[data] then
                -- OVERRIDE_CHARACTER = MUTATORS[data].override_character
                game_state:RequireMod(mod)
                return
            end
        end
    end
end
local function OnLoad()
    
    -- Add the above grafts as mutators
    for id, graft in pairs( MUTATORS ) do
        local path = string.format( "CrossCharacterCampaign:icons/%s.png", id:lower() )
        graft.img = engine.asset.Texture(path, true)
        graft.img_path = graft.img and path
        Content.AddMutatorGraft( id, graft )
    end    

    -- Modify the PlayerAct.InitializeAct function to consider any mutators applied
    PlayerAct.InitializeAct = function( self, game_state, config_options)
    
        local player = game_state:GetPlayerAgent()
        local OVERRIDE_CHARACTER = false
        if TheGame:GetGameState():GetOptions().mutators then
            for id, data in pairs(TheGame:GetGameState():GetOptions().mutators) do
                if MUTATORS[data] and MUTATORS[data].override_character then
                    OVERRIDE_CHARACTER = MUTATORS[data].override_character
                end
            end
        end
        if player == nil then
            player = Agent( TheGame:GetLocalSettings().PLAYER_AGENT or OVERRIDE_CHARACTER or self.background.data.player_agent )
            game_state:AddPlayerAgent( player )
        end
    
        if self.data.starting_fn then
            self.data.starting_fn(player)
        end        
    
        if self.data.entry_point then
            player:MoveToLocation(self.data.entry_point:GetLocation())
        end
    
        self:ApplyNewPlayerConfig( game_state, config_options )
    end

    -- Modify the behavior of GraftCollection.Rewardable so that coin can be rewarded if mutators are enabled
    GraftCollection.Rewardable = function(owner, fn)
        local function Filter( graft_def )
            if TheGame:GetGameState() and TheGame:GetGameState():GetPlayerAgent() and TheGame:GetGameState():GetPlayerAgent().graft_owner:GetGraft( "rook_coin_reward" ) then
                return graft_def.type == GRAFT_TYPE.COMBAT or graft_def.type == GRAFT_TYPE.NEGOTIATION or graft_def.type == GRAFT_TYPE.COIN
            else
                return graft_def.type == GRAFT_TYPE.COMBAT or graft_def.type == GRAFT_TYPE.NEGOTIATION
            end
        end
        
        local collection = GraftCollection(fn):NotUnique():NotLocked():NotBoss():NotUpgraded():Filter( Filter )
        if owner then
            collection:NotInstalled(owner)
            collection:NotRestricted(owner)
        end
        return collection
    end
    require "CrossCharacterCampaign:add_coin_graft_to_reward"

    -- Change sal's brawl graft to general(for now)
    local collection = GraftCollection(function(graft_def) return graft_def.brawl == true end)
    for _, graft in ipairs(collection.items) do
        graft.series = "GENERAL"
    end
    -- Add localization files
    
    
    
end
local function OnPreLoad()
    for k, filepath in ipairs( filepath.list_files( "CrossCharacterCampaign:loc", "*.po", true )) do
        local name = filepath:match( "(.+)[.]po$" )
        print(name)
        if name then
            local id = filepath:match("([^/]+)[.]po$")
            print(id)
            Content.AddPOFileToLocalization(id, filepath)
        end
    end
    print("CrossCharacterCampaign added localization")
end
return {
    version = "1.1.1",
    alias = "CrossCharacterCampaign",
    
    OnLoad = OnLoad,
    OnPreLoad = OnPreLoad,
    OnNewGame = OnNewGame,

    title = "Cross Character Campaign",
    description = 
[[[h1]Cross Character Campaign[/h1]

A mod that allows you to play as other characters in Griftlands.

[h2]How does it work?[/h2]

This mod adds 3 mutators, that allows you to play as the characters in Griftlands.

You can also set the outfit of each character and apply the mutator. Then you can make that character wear the old character's outfit.  

This simply allows you to play a character(with their unique deck, grafts, and mechanics) in other character's story. It doesn't change 
any quests to reflect on the changes. Sometimes picking an option that doesn't make sense will cause the game to crash, so don't trade your non-existing lucky coin with Krog's weighted coin.

This mod also adds another mutator that allows coin grafts to show up as a generic graft reward. Only useful when playing as Rook, obviously.

[b]Notice! The latest version is no longer backwards compatible! If you're on the main branch and haven't moved to experimental, use the "legacy" branch of the source code. On that branch it will never be updated again.[/b]

[h2]How to install?[/h2]

[h3]Directly fron GitHub[/h3]

With the official mod update, you can read about how to set up mods [here](https://forums.kleientertainment.com/forums/topic/116914-early-mod-support/).

1. Find "[user]/AppData/Roaming/Klei/Griftlands/" folder on your computer, or "[user]/AppData/Roaming/Klei/Griftlands_testing/" if you're on experimental. Find the folder with all the autogenerated files, log.txt, and "saves" directory. If you are on Steam, open the folder that starts with "steam-". If you are on Epic, open the folder that contains only hexadecimal code.
2. Create a new folder called "mods" if you haven't already.
3. Clone this repository into that folder.
4. The "modinit.lua" file should be under ".../mods/[insert_repo_name_here]".
5. Volia! Now the mod should work.

[h3]Steam workshop[/h3]

1. Subscribe this item.
2. Enable it in-game.
3. Volia!

[h2]CHANGELOG[/h2]

[h3]1.1.1[/h3]

* Minor update that makes the localization loading part in the OnPreLoad function.

[h3]1.1.0[/h3]

* Workshop support!
* Added preview icon.
* Made it compatible with the latest experimental version(version 429468). This means that the old version probably won't work anymore. 

[h3]1.0.3[/h3]

* Remove an unnecessary dependency, as it causes problems in Experimental.
* Fix bug where playing a game without mutators unlocked will cause the game to crash.
* Changed "Japanese" "localization" to Simplified Chinese localization, since there's now actually Chinese in the game. Also updated the translation for Grafts.
* Add Traditional Chinese localization. They are close enough anyways, might as well do it.

[h3]1.0.2[/h3]

* Adds "Japanese" "localization".
* Adds icons to the new mutators.

[h3]1.0.1[/h3]

* Changed all Sal's brawl grafts to the general series, so other characters can use them.

[h3]1.0.0[/h3]

* A new mutator called "Rewardable Coins". Enable this mutator to allow Rook to acquire non-default coin outside of his campaign! Coins 
will show up as a generic graft reward sometimes.
* Update the UI of pick graft screen so that coin grafts will show up as correct color and correct description.(Still incorrect icon right now, but there's little I can do about it.)]],
    previewImagePath = "preview.png",
}
