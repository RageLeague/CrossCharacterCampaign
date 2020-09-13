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
[[A mod that allows you to play as other characters in Griftlands.
This mod adds 3 mutators, that allows you to play as the characters in Griftlands.
You can also set the outfit of each character and apply the mutator. Then you can make that character wear the old character's outfit.  
This simply allows you to play a character(with their unique deck, grafts, and mechanics) in other character's story. It doesn't change 
any quests to reflect on the changes. Sometimes picking an option that doesn't make sense will cause the game to crash, so don't trade your non-existing lucky coin with Krog's weighted coin.
This mod also adds another mutator that allows coin grafts to show up as a generic graft reward. Only useful when playing as Rook, obviously.]],
    previewImagePath = "preview.png",
}
