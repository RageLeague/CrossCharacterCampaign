MountModData( "CrossCharacterCampaign" )

local player_starts = require "content/player_starts"

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



local function OnLoad()

    
    for id, graft in pairs( MUTATORS ) do
        Content.AddMutatorGraft( id, graft )
    end    


    PlayerAct.InitializeAct = function( self, game_state, config_options)
    
        local player = game_state:GetPlayerAgent()
        local OVERRIDE_CHARACTER = false
        for id, data in pairs(TheGame:GetGameState():GetOptions().mutators) do
            if MUTATORS[data] and MUTATORS[data].override_character then
                OVERRIDE_CHARACTER = MUTATORS[data].override_character
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
end

return {
    OnLoad = OnLoad
}
