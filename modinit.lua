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
        desc = "Play through this campaign as Shel...?",
        override_character = "SHEL",
    },
    play_as_pc_arint =
    {
        name = "Play As Arint",
        desc = "Play through this campaign as Arint",
        override_character = {"PC_ARINT", "PC_ARINT_DEMO"},
    },
    play_as_pc_kashio =
    {
        name = "Play As Kashio",
        desc = "Play through this campaign as Kashio",
        override_character = "KASHIO_PLAYER",
    },
    rook_coin_reward =
    {
        name = "Rewardable Coins",
        desc = "Coins will show up as graft rewards(when applicable, which basically means playing as Rook)",
    },
    play_as_random =
    {
        name = "Play As Random",
        desc = "Play as a random character. Who knows what's it going to be?",
        loc_strings = {
            SELECTED_CHAR = "(Current character: {1#agent})",
        },
        desc_fn = function(self, fmt_str)
            if TheGame:GetGameState() then
                return fmt_str .. "\n" .. loc.format(self:GetDef():GetLocalizedString( "SELECTED_CHAR" ), TheGame:GetGameState():GetPlayerAgent())
            else
                return fmt_str
            end
        end,
        override_character = true,
    }
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
    if graft.override_character and type(graft.override_character) == "table" then
        for i, id in ipairs(graft.override_character) do
            if GetPlayerBackground(id) then
                graft.override_character = id
                break
            end
        end
    end
    if graft.override_character and graft.override_character ~= true and not GetPlayerBackground(graft.override_character) then
        print("Invalid character, skip adding")
        return
    end
    if graft.override_character and graft.override_character ~= true and GetPlayerBackground(graft.override_character):GetModID() then
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
            if graft.override_character and type(graft.override_character) == "table" then
                for i, id in ipairs(graft.override_character) do
                    if GetPlayerBackground(id) then
                        graft.override_character = id
                        break
                    end
                end
            end
            if graft.override_character and graft.override_character ~= true and not GetPlayerBackground(graft.override_character) then
                -- do nothing because that character doesn't exist.
                print(loc.format("Not a player background:{1}", graft.override_character))
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
    -- Now there's the load order thing i wrote, it isn't necessary anymore.
    -- if loaded_at_least_one_item then
    --     -- print(LoadMutators)
    --     return LoadMutators
    -- end
end
local function DetermineOverrideCharacter(game_state)
    local OVERRIDE_CHARACTER = nil
    if game_state:GetOptions().mutators then
        for id, data in pairs(game_state:GetOptions().mutators) do
            if Content.GetGraft(data) and Content.GetGraft(data).override_character then
                if Content.GetGraft(data).override_character == true then
                    -- local other_mutators = shallowcopy(loaded_override_grafts)
                    -- table.arrayremove(other_mutators, data)
                    -- data = TheGame:GetGameProfile():GetNoStreakRandom("CCC_RANDOM_CHARACTER_MUTATOR", other_mutators, 2)
                    local background_ids = copykeys(Content.internal.PLAYER_DATA)

                    local selected_background = TheGame:GetGameProfile():GetNoStreakRandom("CCC_RANDOM_CHARACTER_BACKGROUND", background_ids, 2)
                    OVERRIDE_CHARACTER = GetPlayerBackground(selected_background)
                else

                    local player_background = GetPlayerBackground(Content.GetGraft(data).override_character)
                    if player_background then
                        OVERRIDE_CHARACTER = player_background
                    end
                    -- print("Override character to: "..OVERRIDE_CHARACTER)
                end
            end
        end
    end
    return OVERRIDE_CHARACTER and OVERRIDE_CHARACTER:CreateAgent()
end
local function OnLoad()

    local load_fn = LoadMutators()

    local old_fn = PlayerAct.InitializeAct
    -- Modify the PlayerAct.InitializeAct function to consider any mutators applied
    PlayerAct.InitializeAct = function( self, game_state, config_options)
        if game_state:GetPlayerAgent() == nil then
            local OVERRIDE_CHARACTER = DetermineOverrideCharacter(game_state)
            if OVERRIDE_CHARACTER then
                -- local player = Agent(OVERRIDE_CHARACTER)
                game_state:AddPlayerAgent( OVERRIDE_CHARACTER )
            end
        end
        old_fn(self, game_state, config_options)
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
        local lang_id = name:match("([_%w]+)$")
        lang_id = lang_id:gsub("_", "-")
        -- require(name)
        print(lang_id)
        for id, data in pairs(Content.GetLocalizations()) do
            if data.default_languages and table.arraycontains(data.default_languages, lang_id) then
                Content.AddPOFileToLocalization(id, filepath)
            end
        end
    end
    print("CrossCharacterCampaign added localization")
end
return {
    version = "1.4.1",
    alias = "CrossCharacterCampaign",

    OnLoad = OnLoad,
    OnPreLoad = OnPreLoad,
    OnNewGame = OnNewGame,

    load_after = {
        -- This mod loads after language mods, to add the po files to that language.
        "CHS",
        "CHT",
        -- This mod loads after character mods
        "LOSTPASSAGE",
        "ARINTDEMO",
        "RISE"
    },

    title = "Cross Character Campaign",
    description =
[[This mod adds mutators that allows you to play as other characters in Griftlands.
You can also set the outfit of each character and apply the mutator. Then you can make that character wear the old character's outfit.
This mod also adds another mutator that allows coin grafts to show up as a generic graft reward and an additional mutator that will randomly select a character.]],
    previewImagePath = "preview.png",
}
