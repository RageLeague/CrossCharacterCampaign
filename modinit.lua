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
        -- exclusion_ids = { "play_as_rook", "play_as_smith" },
    },
    play_as_rook =
    {
        name = "Play As Rook",
        desc = "Play through this campaign as Rook",
        override_character = "ROOK",
        -- exclusion_ids = { "play_as_sal", "play_as_smith" },
    },
    play_as_smith =
    {
        name = "Play As Smith",
        desc = "Play through this campaign as Smith",
        override_character = "SMITH",
        -- exclusion_ids = { "play_as_sal", "play_as_rook" },
    },
    play_as_pc_shel =
    {
        name = "Play As Shel",
        desc = "I mean... You do you. I'm not here to judge",
        override_character = "SHEL",
    },
    rook_coin_reward =
    {
        name = "Rewardable Coins",
        desc = "Coins will show up as graft rewards(when applicable, which basically means playing as Rook)",
    },
}
local loaded_override_grafts = {}
local function OnNewGame(mod, game_state)
    if TheGame:GetGameState():GetOptions().mutators then
        for id, data in pairs(TheGame:GetGameState():GetOptions().mutators) do
            if MUTATORS[data] then
                -- OVERRIDE_CHARACTER = MUTATORS[data].override_character
                game_state:RequireMod(mod)
                if MUTATORS[data].character_from_mod then
                    game_state:RequireMod(Content.FindMod(MUTATORS[data].character_from_mod))
                end
                return
            end
        end
    end
end
local function UpdateExculsionIDs()
    for i, id in ipairs(loaded_override_grafts) do
        local exclusion_ids = shallowcopy(loaded_override_grafts)
        table.arrayremove(exclusion_ids, id)
        Content.GetGraft(id).exclusion_ids = exclusion_ids
    end
end
-- for if other mods want to use this function
function AddCharacterOverrideMutator(id, graft)
    -- if graft.override_character then
    --     graft.exclusion_ids = shallowcopy(loaded_override_grafts)
    -- end
    if graft.override_character and GetPlayerBackground(graft.override_character):GetModID() then
        graft.character_from_mod = GetPlayerBackground(graft.override_character):GetModID()
    end
    Content.AddMutatorGraft( id, graft )
    print("Loaded graft: "..id)
    if graft.override_character then
        table.insert(loaded_override_grafts, id)
        UpdateExculsionIDs()
    end
end
local function LoadMutators()
    print("You called?")
    local loaded_at_least_one_item = false
    -- Add the above grafts as mutators
    for id, graft in pairs( MUTATORS ) do
        if not graft.loaded then
            print("Try load graft:"..id)
            if graft.override_character and not GetPlayerBackground(graft.override_character) then
                -- do nothing because that character doesn't exist.
                print("Not a player background:"..graft.override_character)
            else
                
                local path = string.format( "CrossCharacterCampaign:icons/%s.png", id:lower() )
                graft.img = engine.asset.Texture(path, true)
                graft.img_path = graft.img and path
                AddCharacterOverrideMutator(id, graft)
                graft.loaded = true
                loaded_at_least_one_item = true
            end
        end
    end
    if loaded_at_least_one_item then
        -- print(LoadMutators)
        return LoadMutators
    end
end
local function OnLoad()
    
    local load_fn = LoadMutators()

    -- Modify the PlayerAct.InitializeAct function to consider any mutators applied
    PlayerAct.InitializeAct = function( self, game_state, config_options)
    
        local player = game_state:GetPlayerAgent()
        local OVERRIDE_CHARACTER = false
        if TheGame:GetGameState():GetOptions().mutators then
            for id, data in pairs(TheGame:GetGameState():GetOptions().mutators) do
                if Content.GetGraft(data).override_character then
                    local player_background = GetPlayerBackground(Content.GetGraft(data).override_character)
                    if player_background then
                        OVERRIDE_CHARACTER = player_background.data.player_agent
                        print("Override character to: "..OVERRIDE_CHARACTER)
                    end
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
    -- local collection = GraftCollection(function(graft_def) return graft_def.brawl == true end)
    -- for _, graft in ipairs(collection.items) do
    --     graft.series = "GENERAL"
    -- end
    -- Add localization files
    
    return load_fn
    
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
    version = "1.2.0",
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
