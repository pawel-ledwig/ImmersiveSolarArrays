require "SolarUI/ISAUI"
local rGood, gGood, bGood, rBad, gBad, bBad = ISAMenu.getRGB()
local richGood, richBad, richNeutral = ISAMenu.getRGBRich()

ISACursor = {}
ISACursor.Type = "ISACursor"

function ISACursor:new(player,square)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerObj = getSpecificPlayer(player)

    o.xJoypad = -1
    o.xJoy = square:getX()
    o.yJoy = square:getY()
    o.joyfocus = not wasMouseActiveMoreRecentlyThanJoypad() and JoypadState.players[player+1]
    if o.joyfocus then
        setJoypadFocus(player, o)
    else
        getCell():setDrag(o, player)
    end
    return o
end

function ISACursor:derive(type)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = type
    return o
end

function ISACursor:rotateMouse(x,y) end
function ISACursor:rotateKey(key) end
function ISACursor:getSprite() end
function ISACursor:isValid(square,north) end
function ISACursor:render(x,y,z,square) end
function ISACursor:tryBuild(x,y,z) end
function ISACursor:reinit() end
function ISACursor:onLoseJoypadFocus(joypadData) self:close() end
function ISACursor:onGainJoypadFocus(joypadData)
    self.joyfocus = joypadData
    getCell():setDrag(self,self.player)
end
function ISACursor:onJoypadDown(button, joypadData) return self:onJoypadPressButton(nil, joypadData, button) end
--function ISACursor:onJoypadPressButton(joypadIndex, joypadData, button) end
function ISACursor:onJoypadPressButton(joypadIndex, joypadData, button) --onPressButtonNoFocus
    if button == Joypad.AButton and self.valid then self:tryBuild() end
    if button == Joypad.BButton then self:close() end
    if button == Joypad.YButton then
        self.xJoy = self.playerObj:getCurrentSquare():getX()
        self.yJoy = self.playerObj:getCurrentSquare():getY()
    end
end
function ISACursor:onJoypadDirDown(joypadData) self.yJoy = self.yJoy + 1 end
function ISACursor:onJoypadDirUp(joypadData) self.yJoy = self.yJoy - 1 end
function ISACursor:onJoypadDirRight(joypadData) self.xJoy = self.xJoy + 1 end
function ISACursor:onJoypadDirLeft(joypadData) self.xJoy = self.xJoy - 1 end
function ISACursor:getAPrompt() return self.valid and "Interact" end --text
function ISACursor:getBPrompt() return getText("UI_Cancel") end
function ISACursor:getYPrompt() return getText("IGUI_SetCursorToPlayerLocation") end
function ISACursor:getLBPrompt() end
function ISACursor:getRBPrompt() end

function ISACursor:toString() return self.Type end

function ISACursor:hideTooltip()
    if self.tooltip then
        self.tooltip:removeFromUIManager()
        self.tooltip:setVisible(false)
        self.tooltip = nil
    end
end

function ISACursor:deactivate()
    self:hideTooltip()
    if self.joyfocus then setPrevFocusForPlayer(self.player) end
end

function ISACursor:close()
    getCell():setDrag(nil,self.player)
end

function ISACursor:isVisible()
    return getCell():getDrag(self.player) == ISACursor.cursor
end

ISAConnectPanelCursor = ISACursor:derive("ISAConnectPanelCursor")

function ISAConnectPanelCursor:new(player,square, powerbank)
    local o = ISACursor.new(self,player, square)
    --o.isoPb = powerbank
    o.luaPb = CPowerbankSystem.instance:getLuaObjectOnSquare(powerbank:getSquare())
    return o
end

function ISAConnectPanelCursor:isValid(square,...)
    square = self.joyfocus and getSquare(self.xJoy,self.yJoy,self.playerObj:getZ()) or square
    if self.sq ~= square then
        self.sq = square
        local panel = ISAScan.findTypeOnSquare(square,"Panel")
        self.panel = panel
        if not panel then
            self.valid = false
        else
            self.valid = panel:getSquare():isOutside()
            self.connected = self:isConnected()
        end
    end
    return self.valid
end

function ISAConnectPanelCursor:render(x,y,z,...)
    if not (self.luaPb and self.luaPb:getIsoObject()) then return self:close() end
    if self.joyfocus then x,y = self.xJoy,self.yJoy end
    if not self.floorSprite then
        self.floorSprite = IsoSprite.new()
        self.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
    end

    if self.valid then
        self.floorSprite:RenderGhostTileColor(x, y, z, rGood, gGood, bGood, 0.8)
    else
        self.floorSprite:RenderGhostTileColor(x, y, z, rBad, gBad, bBad, 0.8)
    end

    self:renderTooltip()
end

function ISAConnectPanelCursor:renderTooltip()
    local tooltip = self.tooltip
    if not tooltip then
        tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setVisible(true)
        tooltip:addToUIManager()
        tooltip.maxLineWidth = 1000
        if self.joyfocus then tooltip.followMouse = false; tooltip.contextMenu = self end
        self.tooltip = tooltip
    end
    if not self.panel then
        tooltip.description = richBad .. getText("Tooltip_ISA_NoPanels")
    else
        tooltip.description = self.connected and richGood .. getText("ContextMenu_ISA_Connect_Panel_toolTip_isConnected") or richNeutral .. getText("ContextMenu_ISA_Connect_Panel_toolTip_isConnected_false")
        if not self.valid then tooltip.description = string.format("%s\n%s%s",tooltip.description,richBad,getText("ContextMenu_ISA_Connect_Panel_toolTip_isOutside")) end
    end
end

function ISAConnectPanelCursor:tryBuild()
    return ISAMenu.onConnectPanel(nil,self.player,self.panel,self.luaPb)
end

function ISAConnectPanelCursor:getAPrompt()
    if self.valid then return getText("ContextMenu_ISA_Connect_Panel") end
end

function ISAConnectPanelCursor:isConnected()
    local dataPb, luaPb = self.panel:getModData().powerbank, self.luaPb
    if dataPb and dataPb.x == luaPb.x and dataPb.y == luaPb.y and dataPb.z == luaPb.z then
        local x,y,z = self.panel:getX(), self.panel:getY(), self.panel:getZ()
        self.luaPb:updateFromIsoObject()
        for _,panel in ipairs(self.luaPb.panels) do
            if x == panel.x and y == panel.y and z == panel.z then return true end
        end
    end
end