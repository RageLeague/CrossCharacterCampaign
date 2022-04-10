local CCCUtil = class("CCCUtil")

CCCUtil.MUTATORS =
{
    play_as_sal =
    {
        name = "Play As Sal",
        desc = "Play through this campaign as Sal",
        override_character = "SAL",
    },
    play_as_rook =
    {
        name = "Play As Rook",
        desc = "Play through this campaign as Rook",
        override_character = "ROOK",
    },
    play_as_smith =
    {
        name = "Play As Smith",
        desc = "Play through this campaign as Smith",
        override_character = "SMITH",
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
    play_as_victor =
    {
        name = "Play As Victor",
        desc = "Play through and die in this campaign as Victor",
        override_character = "VICTOR",
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

CCCUtil.LOADED_OVERRIDE_GRAFTS = {}

function CCCUtil.UpdateExclusionIDs()
    for i, id in ipairs(CCCUtil.LOADED_OVERRIDE_GRAFTS) do
        local exclusion_ids = shallowcopy(CCCUtil.LOADED_OVERRIDE_GRAFTS)
        table.arrayremove(exclusion_ids, id)
        Content.GetGraft(id).exclusion_ids = exclusion_ids
    end
end

-- for if other mods want to use this function
function CCCUtil.AddCharacterOverrideMutator(id, graft)
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
        table.insert(CCCUtil.LOADED_OVERRIDE_GRAFTS, id)
        CCCUtil.UpdateExclusionIDs()
    end
end

function CCCUtil.LoadMutators()
    local loaded_at_least_one_item = false
    -- Add the above grafts as mutators
    for id, graft in pairs( CCCUtil.MUTATORS ) do
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
                CCCUtil.AddCharacterOverrideMutator(id, graft)
                graft.loaded = true
                loaded_at_least_one_item = true
            end
        end
    end
end

function CCCUtil.DetermineOverrideCharacter(game_state)
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

local old_fn = PlayerAct.InitializeAct
-- Modify the PlayerAct.InitializeAct function to consider any mutators applied
PlayerAct.InitializeAct = function( self, game_state, config_options)
    if game_state:GetPlayerAgent() == nil then
        local OVERRIDE_CHARACTER = CCCUtil.DetermineOverrideCharacter(game_state)
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
