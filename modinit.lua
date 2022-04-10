-- MountModData( "CrossCharacterCampaign" )

-- local player_starts = require "content/player_starts"

local filepath = require "util/filepath"
local loaded_override_grafts = {}
local function OnNewGame(mod, game_state)
    if TheGame:GetGameState():GetOptions().mutators then
        for id, data in pairs(TheGame:GetGameState():GetOptions().mutators) do
            if CCCUtil.MUTATORS[data] then
                -- OVERRIDE_CHARACTER = MUTATORS[data].override_character
                game_state:RequireMod(mod)
                if CCCUtil.MUTATORS[data].character_from_mod then
                    game_state:RequireMod(Content.FindMod(CCCUtil.MUTATORS[data].character_from_mod))
                end
                return
            end
        end
    end
end

local function OnLoad()

    require "CrossCharacterCampaign:cccutil"

    require "CrossCharacterCampaign:add_coin_graft_to_reward"

    return CCCUtil.LoadMutators

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
    if Content.GetModSetting(mod, "joke_chinese_translation") then
        for k, filepath in ipairs( filepath.list_files( "CrossCharacterCampaign:jocloc", "*.po", true )) do
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
    end
    print("CrossCharacterCampaign added localization")
end

local MOD_OPTIONS =
{
    {
        title = "Joke Chinese Translation (Requires Restart)",
        spinner = true,
        key = "joke_chinese_translation",
        default_value = false,
        values =
        {
            { name="Disabled", desc="It does nothing if you are not in English, so don't worry about it.", data = false },
            { name="Enabled", desc="You probably won't understand it anyway. I'm not just saying that because it's in Chinese.", data = true },
        },
    }
}

return {
    version = "2.0.0",
    alias = "CrossCharacterCampaign",

    OnLoad = OnLoad,
    OnPreLoad = OnPreLoad,
    OnNewGame = OnNewGame,

    mod_options = MOD_OPTIONS,

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
