require "ui/widgets/optionpicker"
require "ui/widgets/screen"
require "ui/widgets/tooltip_graft"
require "ui/screens/replacegraftscreen"

local filepath = require "util/filepath"

local GRAFT_COLORS = {
    [GRAFT_TYPE.NEGOTIATION] = UICOLOURS.NEGOTIATION,
    [GRAFT_TYPE.COMBAT] = UICOLOURS.FIGHT,
    [GRAFT_TYPE.COIN] = UICOLOURS.MONEY,
}
local GRAFT_NAME = {
    [GRAFT_TYPE.NEGOTIATION] = "UI.GRAFT_COLLECTION.SLOT_TYPE_NEGOTIATION",
    [GRAFT_TYPE.COMBAT] = "UI.GRAFT_COLLECTION.SLOT_TYPE_COMBAT",
    [GRAFT_TYPE.COIN] = "UI.GRAFT_COLLECTION.SLOT_TYPE_COIN",
}

local PickGraftOption = Widget.PickGraftOption
local oldInitFunction = PickGraftOption.init
local newGraftOptionsInitFn = function(self, graft)
    oldInitFunction(self, graft)
    local graftType = graft:GetType()
    local graftColor = graftType and GRAFT_COLORS[graftType] or UICOLOURS.FIGHT
    -- Not the name of the graft, the type name
    local graftName = graftType and LOC(GRAFT_NAME[graftType]) or LOC"UI.GRAFT_COLLECTION.SLOT_TYPE_NONE"
    self.bg:SetTintColour(graftColor)
    self.gradient:SetTintColour(graftColor)
    self.graft_frame:SetTintColour(graftColor)
    self.title:SetGlyphColour(graftColor)
    self.overlay:SetTintColour(graftColor)

    local testIcon = engine.asset.Texture("UI/ic_subcard_negotiation.tex")
    self.class_label.bg:SetTintColour(graftColor)
    self.class_label.icon:SetTintColour(graftColor)
    self.class_label.label:SetText(graftName)
    self.class_label.label:SetTintColour(graftColor)

    local rarity_color = MakeColourString( HexColour( CARD_RARITY_COLOURS[ self.graft:GetRarity() or CARD_RARITY.UNIQUE ] ) )
    local rarity_name = GetCardRarityString( self.graft:GetRarity() )
    local rarity_icon_string = GetCardRarityIconString( self.graft:GetRarity() )

    self.subtitle:SetText( string.upper( loc.format( LOC"UI.GRAFT_COLLECTION.SLOT_SUBTITLE", rarity_color, rarity_name, graftName, rarity_icon_string ) ) )
end
PickGraftOption.init = newGraftOptionsInitFn


Content.ExportTextureToPNG = function (path)
    local texture = engine.asset.Texture(path..".tex")
    print(texture)
    UIHelpers.SaveTextureAsPNG(texture, "image_exports/".. path)
    print("Saved image to: image_exports/"..path..".png")
end
Content.ExportAllTextureFromPath = function (path)
    for k, filepath in ipairs( filepath.list_files( path, "*.tex", true )) do
        local name = filepath:match( "(.+)[.]tex$" )
        Content.ExportTextureToPNG(name)
    end
end
-- Content.ExportTextureToPNG("icons/mutators/discharged")
-- Content.ExportTextureToPNG("battle/accelerant")