-- Coding by skidhi
-- SFX by skidhi and tpc

-- DONT YOU DARE STEAL THIS CODE!!!!!! i dont think anyone will tho.....

-- Trash and Enemy cell is still buggy
local timer, selectedCell, selectedRot, rotatetimer, selectCellTimer = 0, 2, 0, 0, 0
local cells, gridX, gridY = {}, 50, 50
local halfpi, tex, sfx, cellSize = math.pi/2, {}, {}, nil
local camX, camY, originX, originY = gridX/2, gridY/2, nil, nil
local screenWidth, screenHeight
local simulate, simulatetimer = false, 0
local moverTypes, unbreakables, pullerTypes = {2,18}, {1}, {15}
local buttons, buttonclicked, sinetimer = {}, false, 0
local emptygrid, ispressingbutton, ticks = nil, false, 0
local music, list, cat = love.audio.newSource("thefinalcell.mp3", "stream") ,nil, nil

local weightMasses = {{type = 14, weight = 1}}

cats = {}
cats.movers = {name = "Movers", cells = {2,18,19}, icon = tex[2], max = 5}
cats.pullers = {name = "Pullers", cells = {15}, icon = tex[15], max = 5}
cats.pushables = {name = "Pushables", cells = {3,5,6,7,8}, icon = tex[3], max = 5}
cats.walls = {name = "Walls", cells = {1}, icon = tex[1], max = 5}

lists = {}
lists[1] = {name = "Movers", cells = {cats.movers, cats.pullers}, icon = tex[2]}
lists[2] = {name = "Basic", cells = {cats.pushables, cats.walls}, icon = tex[3]}

music:setLooping(true)
music:play()
-- Load assets
function NewTexture(name, key)
    tex[key] = love.graphics.newImage("textures/"..name..".png")
end

function NewSound(name, key)
    sfx[key] = {sound = love.audio.newSource("sfx/"..name, "static"), name = name}
end

NewTexture("empty", 0)
NewTexture("wall", 1)
NewTexture("mover", 2)
NewTexture("pushable", 3)
NewTexture("generator", 4)
NewTexture("slide", 5)
NewTexture("onedir", 6)
NewTexture("twodir", 7)
NewTexture("threedir", 8)
NewTexture("cwrotator", 9)
NewTexture("ccwrotator", 10)
NewTexture("180rotator", 11)
NewTexture("trash", 12)
NewTexture("enemy", 13)
NewTexture("weight", 14)
NewTexture("puller", 15)
NewTexture("straightdiverger", 16)
NewTexture("diamover", 17)
NewTexture("fastmover", 18)
NewTexture("slowmover", 19)

NewSound("destroy.wav", 1)

cellinfo = {
    [1] = "A wall, it cannot be pushed or destroyed",
    [2] = "Moves cells in front of it with a pushing force",
    [3] = "Does nothing, but can be moved around",
    [4] = "Gets the cell behind it and duplicates it to the front.\nIf there is a cell in front of it then it pushing that cell away\nto make room for another",
    [5] = "Can only be moved on its sides",
    [6] = "Can only be moved in its own direction",
    [7] = "Can only be moved forwards and downwards",
    [8] = "Can be moved in any direction but backwards",
    [9] = "Rotates adjacent cells 90 degrees clockwise",
    [10] = "Rotates adjacent cells 90 degrees counter-clockwise",
    [11] = "Rotates adjacent cells 180 degrees",
    [12] = "Deletes cells that move into it",
    [13] = "A Trash cell that deletes itself as well",
    [14] = "Subtracts 1 bias from an incoming force",
    [15] = "Moves the cells behind it with it using a pulling force; It \ncannot move cells in front of it",
    [16] = "Diverges cells through it when they enter either side",
    [17] = "A mover that moves diagonally",
    [18] = "A mover that moves forward twice every tick",
    [19] = "A mover that moves forward once every two ticks"
}

myFont = love.graphics.newFont("7-12-serif-bold.ttf", 16) -- Load custom font at size 32
love.graphics.setFont(myFont)
cellSize = 32/tex[0]:getWidth()
originX = tex[1]:getWidth() / 2
originY = tex[1]:getHeight() / 2

function PlaySound(name)
    for s = 1, #sfx do
        if sfx[s].name == name then
            sfx[s].sound:play()
        end
    end
end

function RawDeleteCell(idx)
    table.remove(cells, idx)
end

function DeleteCell(idx)
    cells[idx].x = 10000
    cells[idx].y = 10000
end

function lerp(s, e, t)
    return s + (e - s) * t
end

function math.round(num)
    return math.floor(num+0.5)
end

function DrawCell(tex, x, y, dir)
    local cellX = (x-1)*32-camX
    local cellY = (y-1)*32+camY
    DrawBasic(tex, cellX, cellY, dir)
end

function DrawBasic(tex, x, y, dir)
    love.graphics.draw(tex, x, y, dir*halfpi, cellSize, cellSize, originX, originY)
end

function RotateCell(x, y, amt)
    if GetID(x, y) then
        if not(contains(unbreakables, cells[GetID(x, y)].type)) then
            cells[GetID(x, y)].dir = cells[GetID(x, y)].dir + amt
        end
    end
end

function DrawBGCells()
    for x = 1, gridX do
        for y = 1, gridY do
            DrawCell(tex[0], x, y, 0)
        end
    end
end

function DrawGridCells()
    for _,c in ipairs(cells) do
        DrawCell(tex[c.type], lerp(c.oldx, c.x, timer), lerp(c.oldy, c.y, timer), lerp(c.olddir, c.dir, timer))    
    end
end

function GetAdjacentNeighbors(id)
    return {[0]=GetID(cells[id].x+1,cells[id].y),GetID(cells[id].x,cells[id].y+1),GetID(cells[id].x-1,cells[id].y),GetID(cells[id].x,cells[id].y-1)}
end

function GetDiagonalNeighbors(id)
    return {[0.5]=GetID(cells[id].x+1,cells[id].y+1),[1.5]=GetID(cells[id].x-1,cells[id].y+1),[2.5]=GetID(cells[id].x-1,cells[id].y+1),[3.5]=GetID(cells[id].x+1,cells[id].y-1)}
end

function GetNeighbors(id)
    local neightbor = {}
    neightbor[0]=GetID(cells[id].x+1,cells[id].y)
    neightbor[0.5]=GetID(cells[id].x+1,cells[id].y+1)
    neightbor[1]=GetID(cells[id].x,cells[id].y+1)
    neightbor[1.5]=GetID(cells[id].x-1,cells[id].y+1)
    neightbor[2]=GetID(cells[id].x-1,cells[id].y)
    neightbor[2.5]=GetID(cells[id].x-1,cells[id].y+1)
    neightbor[3]=GetID(cells[id].x,cells[id].y-1)
    neightbor[3.5]=GetID(cells[id].x+1,cells[id].y-1)
    return neightbor
end

function PlaceCell(type, x, y, dir, inSimulation, oldx, oldy)
    if x > 0 and x < gridX + 1 and y > 0 and y < gridY + 1 then
        cells[#cells+1] = {type = type, x = x, y = y, dir = dir, oldx = oldx or x, oldy = oldy or y, olddir = dir, inSimulation = inSimulation, updated = inSimulation}
    end
end

function selectCell(id)
    selectedCell = id
    cat = nil
    list = nil
end

function DrawHoverCell(tex, x, y, dir)
    love.graphics.setColor(1, 1, 1, 0.5)
    DrawCell(tex, x, y, dir)
    love.graphics.setColor(1, 1, 1, 1)
end

function resetGrid()
    for i = 1, #cells do
        RawDeleteCell(1)
    end
    for x = 1, gridX do
        for y = 1, gridY do
            if x == 1 or x == gridX or y == 1 or y == gridY then
                PlaceCell(1, x, y, 0, false)
            end
        end
    end
    ticks = 0
end

function NewButton(tex, x, y, w, h, dir, onclick)
    buttons[#buttons+1] = {tex = tex, x = x, y = y, w = w, h = h, dir = dir, onclick = onclick}
end

function isMouseInArea(x1, x2, y1, y2)
    local x, y = love.mouse.getPosition()
    local minX, maxX = math.min(x1, x2), math.max(x1, x2)
    local minY, maxY = math.min(y1, y2), math.max(y1, y2)

    return x >= minX and x <= maxX and y >= minY and y <= maxY
end

function DrawButtons()
    for i, b in ipairs(buttons) do
        if isMouseInArea(b.x - b.w*16/2+(b.w == 2 and 16 or 0), b.x + b.w*16/2+(b.w == 2 and 16 or 0), b.y - b.h*16/2+(b.h == 2 and 16 or 0), b.y + b.h*16/2+(b.h == 2 and 16 or 0)) then
            if love.mouse.isDown(1) and not(buttonclicked) then
                love.graphics.setColor(.8, .8, .8, 1)
                b.onclick()
                if i == 1 then
                    if simulate then
                        b.tex = tex[5]
                        b.dir = 1
                    else
                        b.tex = tex[2]
                        b.dir = 0
                    end
                end
                if i == 1 and b.tex == tex[2] then
                    b.onclick = function() simulate = true end
                end
                if i == 1 and b.tex == tex[5] then
                    b.onclick = function() simulate = false end
                end
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
        else
            love.graphics.setColor(1, 1, 1, .75)
        end
        if i == 1 then
            if simulate then
                b.tex = tex[5]
                b.dir = 1
            else
                b.tex = tex[2]
                b.dir = 0
            end
        end
        love.graphics.draw(b.tex, b.x, b.y, b.dir * halfpi, b.w, b.h, b.w*b.w/2, b.h*b.h/2)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function PushCell(x, y, idx, dir)
    local cx = 0
    local cy = 0
    dir = dir%4
    if dir == 0 then cx = cx + 1 end
    if dir == 1 then cy = cy + 1 end
    if dir == 2 then cx = cx - 1 end
    if dir == 3 then cy = cy - 1 end
    local targetX, targetY = x+cx, y+cy
    if not(GetID(x, y)) then return end
    if contains(unbreakables, cells[idx].type) then
        force = 0
        return
    end
    if cells[idx].type == 16 then
        if dir%2 == cells[idx].dir%2 then
            PushCell(targetX, targetY, GetID(targetX, targetY), dir)
            return
        end
    end
    if cells[idx].type == 12 then
        return
    end
    if cells[idx].type == 13 then
        return
    end
    if GetID(targetX, targetY) then
        if contains(moverTypes, cells[GetID(targetX, targetY)].type) then
            if dir == (cells[GetID(targetX, targetY)].dir + 2)%4 then
                force = force - 1
            end
            if dir == cells[GetID(targetX, targetY)].dir then
                force = force + 1
            end
        end
    end
    if cells[idx].type == 5 then
        if dir%2 ~= (cells[idx].dir)%2 then
            force = 0
            return
        end
    end
    if cells[idx].type == 6 then
        if dir ~= cells[idx].dir%4 then
            force = 0
            return
        end
    end
    if cells[idx].type == 7 then
        if dir ~= cells[idx].dir%4 and dir ~= (cells[idx].dir + 1)%4 then
            force = 0
            return
        end
    end
    if cells[idx].type == 8 then
        if dir == (cells[idx].dir + 2)%4 then
            force = 0
            return
        end
    end
    for i, c in ipairs(weightMasses) do
        if c.type == cells[idx].type then
            force = force - c.weight
        end
    end
    if GetID(targetX, targetY) and cells[GetID(targetX, targetY)].type == 12 then
        PlaySound("destroy.wav")
        return DeleteCell(idx)
    end
    if GetID(targetX, targetY) and cells[GetID(targetX, targetY)].type == 13 then
        PlaySound("destroy.wav")
        DeleteCell(GetID(targetX, targetY))
        return DeleteCell(idx)
    end
    if force > 0 then
        if GetID(targetX, targetY) then
            PushCell(targetX, targetY, GetID(targetX, targetY), dir)
        end
    end
    while true do
        if GetID(targetX, targetY) then
            if cells[GetID(targetX, targetY)].type == 16 then
                if dir%2 == cells[GetID(targetX, targetY)].dir%2 then
                    targetX = targetX + cx
                    targetY = targetY + cy
                else
                    break
                end
            else
                break
            end
        else
            break
        end
    end
    if force > 0 then
        if not(GetID(targetX, targetY)) then
            cells[idx].x = targetX
            cells[idx].y = targetY
        end
    end
end

function PullCell(x, y, idx, dir, ignoreblockage)
    local cx = 0
    local cy = 0
    dir = dir%4
    if dir == 0 then cx = cx + 1 end
    if dir == 1 then cy = cy + 1 end
    if dir == 2 then cx = cx - 1 end
    if dir == 3 then cy = cy - 1 end
    local targetX, targetY = x+cx, y+cy
    local backX, backY = x-cx, y-cy
    if contains(unbreakables, cells[idx].type) then
        force = 0
        return
    end
    if cells[idx].type == 12 then
        return
    end
    if cells[idx].type == 13 then
        return
    end
    if cells[idx].type == 5 then
        if dir%2 ~= (cells[idx].dir)%2 then
            force = 0
            return
        end
    end
    if cells[idx].type == 6 then
        if dir ~= cells[idx].dir%4 then
            force = 0
            return
        end
    end
    if cells[idx].type == 7 then
        if dir ~= cells[idx].dir%4 and dir ~= (cells[idx].dir + 1)%4 then
            force = 0
            return
        end
    end
    if cells[idx].type == 8 then
        if dir == (cells[idx].dir + 2)%4 then
            force = 0
            return
        end
    end
    if GetID(backX, backY) then
        if contains(pullerTypes, cells[GetID(backX, backY)].type) then
            if dir == (cells[GetID(backX, backY)].dir + 2)%4 then
                force = force - 1
            end
            if dir == cells[GetID(backX, backY)].dir then
                force = force + 1
            end
        end
    end
    for i, c in ipairs(weightMasses) do
        if c.type == cells[idx].type then
            force = force - c.weight
        end
    end
    if GetID(targetX, targetY) and cells[GetID(targetX, targetY)].type == 12 then
        PlaySound("destroy.wav")
        return DeleteCell(idx)
    end
    if GetID(targetX, targetY) and cells[GetID(targetX, targetY)].type == 13 then
        PlaySound("destroy.wav")
        DeleteCell(GetID(targetX, targetY))
        return DeleteCell(idx)
    end
    if force > 0 then
        if GetID(targetX, targetY) then
            if ignoreblockage then
                if not(ignoreblockage == "beingpulled") then
                    PushCell(targetX,targetY,GetID(targetX, targetY),dir)
                end
            else
                force = 0
                return
            end
        end
    end
    if force > 0 then
        if GetID(backX, backY) then
            PullCell(backX,backY,GetID(backX, backY),dir,"beingpulled")
        end
    end
    if force > 0 then
        cells[idx].x = targetX
        cells[idx].y = targetY
    end
end

function DoMover(x, y, idx, dir)
    if cells[idx].type == 2 then
        force = 1
        PushCell(x, y, idx, dir)
    end
    if cells[idx].type == 19 then
        if ticks%2 == 1 then
            force = 1
            PushCell(x, y, idx, dir)
        end
    end
    if cells[idx].type == 18 then
        force = 1
        PushCell(x, y, idx, dir)
        x, y = cells[idx].x, cells[idx].y
        force = 1
        PushCell(x, y, idx, dir)
    end
    if cells[idx].type == 15 then
        force = 1
        PullCell(x, y, idx, dir, false)
    end
end

function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

function GetID(x, y)
    for i,c in ipairs(cells) do
        if c.x == x then
            if c.y == y then
                return i
            end
        end   
    end
    return nil
end

function GetXY(id)
    if cells[id] then
        return {x = cells[id].x, y = cells[id].y}
    else
        return nil
    end
end

function updateCell(id, dir)
    dir = dir and dir%4 or "none"
    if dir == 1 then
        for y = gridY, 1, -1 do
            for i, c in ipairs(cells) do
                if c.y == y and c.dir%4 == dir and not(c.inSimulation) and not(c.updated) and c.type == id then
                    if c.type == 2 or c.type == 15 or c.type == 18 or c.type == 19 then
                        DoMover(c.x, c.y, i, dir)
                    end
                    if c.type == 4 then
                        local gcx = 0
                        local gcy = 0

                        if GetID(c.x - gcx, c.y - gcy) then
                            if dir == 0 then gcx = gcx + 1 end
                            if dir == 1 then gcy = gcy + 1 end
                            if dir == 2 then gcx = gcx - 1 end
                            if dir == 3 then gcy = gcy - 1 end

                            if GetID(c.x + gcx, c.y + gcy) and GetID(c.x - gcx, c.y - gcy) then
                                force = 1
                                PushCell(c.x + gcx, c.y + gcy, GetID(c.x + gcx, c.y + gcy), dir)
                            end

                            if not(GetID(c.x + gcx, c.y + gcy)) and GetID(c.x - gcx, c.y - gcy) then
                                PlaceCell(cells[GetID(c.x - gcx, c.y - gcy)].type, c.x + gcx, c.y + gcy, cells[GetID(c.x - gcx, c.y - gcy)].dir, true, c.x, c.y)
                            end
                        end
                    end
                    c.updated = true
                end
            end
        end
        return
    end
    if dir == 0 then
        for x = gridX, 1, -1 do
            for i, c in ipairs(cells) do
                if c.x == x and c.dir%4 == dir and not(c.inSimulation) and not(c.updated) and c.type == id then
                    if c.type == 2 or c.type == 15 or c.type == 18 or c.type == 19 then
                        DoMover(c.x, c.y, i, dir)
                    end
                    if c.type == 4 then
                        local gcx = 0
                        local gcy = 0

                        if GetID(c.x - gcx, c.y - gcy) then
                            if dir == 0 then gcx = gcx + 1 end
                            if dir == 1 then gcy = gcy + 1 end
                            if dir == 2 then gcx = gcx - 1 end
                            if dir == 3 then gcy = gcy - 1 end

                            if GetID(c.x + gcx, c.y + gcy) and GetID(c.x - gcx, c.y - gcy) then
                                force = 1
                                PushCell(c.x + gcx, c.y + gcy, GetID(c.x + gcx, c.y + gcy), dir)
                            end

                            if not(GetID(c.x + gcx, c.y + gcy)) and GetID(c.x - gcx, c.y - gcy) then
                                PlaceCell(cells[GetID(c.x - gcx, c.y - gcy)].type, c.x + gcx, c.y + gcy, cells[GetID(c.x - gcx, c.y - gcy)].dir, true, c.x, c.y)
                            end
                        end
                    end
                    c.updated = true
                end
            end
        end
        return
    end
    if dir == 2 then
        for x = 1, gridX do
            for i, c in ipairs(cells) do
                if c.x == x and c.dir%4 == dir and not(c.inSimulation) and not(c.updated) and c.type == id then
                    if c.type == 2 or c.type == 15 or c.type == 18 or c.type == 19 then
                        DoMover(c.x, c.y, i, dir)
                    end
                    if c.type == 4 then
                        local gcx = 0
                        local gcy = 0

                        if GetID(c.x - gcx, c.y - gcy) then
                            if dir == 0 then gcx = gcx + 1 end
                            if dir == 1 then gcy = gcy + 1 end
                            if dir == 2 then gcx = gcx - 1 end
                            if dir == 3 then gcy = gcy - 1 end

                            if GetID(c.x + gcx, c.y + gcy) and GetID(c.x - gcx, c.y - gcy) then
                                force = 1
                                PushCell(c.x + gcx, c.y + gcy, GetID(c.x + gcx, c.y + gcy), dir)
                            end

                            if not(GetID(c.x + gcx, c.y + gcy)) and GetID(c.x - gcx, c.y - gcy) then
                                PlaceCell(cells[GetID(c.x - gcx, c.y - gcy)].type, c.x + gcx, c.y + gcy, cells[GetID(c.x - gcx, c.y - gcy)].dir, true, c.x, c.y)
                            end
                        end
                    end
                    c.updated = true
                end
            end
        end
        return
    end
    if dir == 3 then
        for y = 1, gridY do
            for i, c in ipairs(cells) do
                if c.y == y and c.dir%4 == dir and not(c.inSimulation) and not(c.updated) and c.type == id then
                    if c.type == 2 or c.type == 15 or c.type == 18 or c.type == 19 then
                        DoMover(c.x, c.y, i, dir)
                    end
                    if c.type == 4 then
                        local gcx = 0
                        local gcy = 0

                        if GetID(c.x - gcx, c.y - gcy) then
                            if dir == 0 then gcx = gcx + 1 end
                            if dir == 1 then gcy = gcy + 1 end
                            if dir == 2 then gcx = gcx - 1 end
                            if dir == 3 then gcy = gcy - 1 end

                            if GetID(c.x + gcx, c.y + gcy) and GetID(c.x - gcx, c.y - gcy) then
                                force = 1
                                PushCell(c.x + gcx, c.y + gcy, GetID(c.x + gcx, c.y + gcy), dir)
                            end

                            if not(GetID(c.x + gcx, c.y + gcy)) and GetID(c.x - gcx, c.y - gcy) then
                                PlaceCell(cells[GetID(c.x - gcx, c.y - gcy)].type, c.x + gcx, c.y + gcy, cells[GetID(c.x - gcx, c.y - gcy)].dir, true, c.x, c.y)
                            end
                        end
                    end
                    c.updated = true
                end
            end
        end
        return
    end
    for i, c in ipairs(cells) do
        if c.type == id then
            if c.type == 9 then
                for j = 0, 3 do
                    if GetAdjacentNeighbors(i)[j] then
                        RotateCell(cells[GetAdjacentNeighbors(i)[j]].x, cells[GetAdjacentNeighbors(i)[j]].y, 1)
                    end
                end
            end
            if c.type == 10 then
                for j = 0, 3 do
                    if GetAdjacentNeighbors(i)[j] then
                        RotateCell(cells[GetAdjacentNeighbors(i)[j]].x, cells[GetAdjacentNeighbors(i)[j]].y, -1)
                    end
                end
            end
            if c.type == 11 then
                for j = 0, 3 do
                    if GetAdjacentNeighbors(i)[j] then
                        RotateCell(cells[GetAdjacentNeighbors(i)[j]].x, cells[GetAdjacentNeighbors(i)[j]].y, -2)
                    end
                end
            end
        end
    end
end

function resetCells()
    for _,c in ipairs(cells) do
        c.oldx = c.x
        c.oldy = c.y
        c.dir = c.dir%4
        c.olddir = c.dir
        c.inSimulation = false
        c.updated = false
    end
end

function HandleCellDesc()
    love.graphics.print(cellinfo[selectedCell], mouseX, mouseY)
end

function UpdateAllMovers()
    updateCell(2, 0)
    updateCell(2, 2)
    updateCell(2, 3)
    updateCell(2, 1)
    updateCell(18, 0)
    updateCell(18, 2)
    updateCell(18, 3)
    updateCell(18, 1)
    updateCell(19, 0)
    updateCell(19, 2)
    updateCell(19, 3)
    updateCell(19, 1)
    updateCell(15, 0)
    updateCell(15, 2)
    updateCell(15, 3)
    updateCell(15, 1)
end

function love.draw()
    DrawBGCells()
    DrawGridCells()
    DrawHoverCell(tex[selectedCell], mouseGridX, mouseGridY, selectedRot)
    DrawButtons()
    HandleCellDesc()
    love.graphics.print("Ticks: "..ticks)
    if love.mouse.isDown(1) then
        if not(buttonclicked) then
            buttonclicked = true
        end
    else
        buttonclicked = false
    end
end

function love.update(dt)
    timer = timer + 0.1
    sinetimer = sinetimer + 0.1

    screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()

    if simulate then
        if timer > 1 then
            timer = 0
            resetCells()
            updateCell(4, 0)
            updateCell(4, 2)
            updateCell(4, 3)
            updateCell(4, 1)
            updateCell(10, nil)
            updateCell(9, nil)
            updateCell(11, nil)
            UpdateAllMovers()
            ticks = ticks + 1
        end
    else
        resetCells()
        timer = 0
    end

    -- Update camera
    if love.keyboard.isDown("w") then camY = camY + 5 end
    if love.keyboard.isDown("s") then camY = camY - 5 end
    if love.keyboard.isDown("a") then camX = camX - 5 end
    if love.keyboard.isDown("d") then camX = camX + 5 end

    -- Turning the selected cell
    if rotatetimer > 0 then
        rotatetimer = rotatetimer + 0.1
    end

    if rotatetimer == 0 then
        if love.keyboard.isDown("e") then 
            selectedRot = (selectedRot + 1)%4
            rotatetimer = rotatetimer + 0.1
        end
    end

    if rotatetimer == 0 then
        if love.keyboard.isDown("q") then 
            selectedRot = (selectedRot - 1)%4
            rotatetimer = rotatetimer + 0.1
        end
    end

    if rotatetimer >= 1 then
        rotatetimer = 0
    end

    -- Changing the selected cell
    if selectCellTimer > 0 then
        selectCellTimer = selectCellTimer + 0.1
    end

    if selectCellTimer == 0 then
        if love.keyboard.isDown("2") then 
            if selectedCell < #tex then
                selectedCell = selectedCell + 1
                selectCellTimer = selectCellTimer + 0.1
            end
        end
    end

    if selectCellTimer == 0 then
        if love.keyboard.isDown("1") then
            if selectedCell > 1 then 
                selectedCell = selectedCell - 1
                selectCellTimer = selectCellTimer + 0.1
            end
        end
    end

    if selectCellTimer >= 1 then
        selectCellTimer = 0
    end

    -- Switch on and off simulation
    if simulatetimer > 0 then
        simulatetimer = simulatetimer + 0.1
    end

    if simulatetimer == 0 then
        if love.keyboard.isDown("space") then 
            simulate = not(simulate)
            simulatetimer = simulatetimer + 0.1
        end
    end

    if simulatetimer >= 1 then
        simulatetimer = 0
    end


    -- Placing cells
    mouseX, mouseY = love.mouse.getPosition()
    mouseGridX = math.round((mouseX+camX)/32)+1
    mouseGridY = math.round((mouseY-camY)/32)+1

    ispressingbutton = false
    for i, b in ipairs(buttons) do
        if isMouseInArea(b.x - b.w*16/2+(b.w == 2 and 16 or 0), b.x + b.w*16/2+(b.w == 2 and 16 or 0), b.y - b.h*16/2+(b.h == 2 and 16 or 0), b.y + b.h*16/2+(b.h == 2 and 16 or 0)) then
            if love.mouse.isDown(1) then
                ispressingbutton = true
            end
        end
    end

    if love.mouse.isDown(1) then
        if mouseGridX > 1 and mouseGridX < gridX and mouseGridY > 1 and mouseGridY < gridY and not(ispressingbutton) then
            if GetID(mouseGridX, mouseGridY) then
                RawDeleteCell(GetID(mouseGridX, mouseGridY))
            end
            PlaceCell(selectedCell, mouseGridX, mouseGridY, selectedRot, false)
        end
    end

    if love.mouse.isDown(2) then
        if mouseGridX > 1 and mouseGridX < gridX and mouseGridY > 1 and mouseGridY < gridY then
            if GetID(mouseGridX, mouseGridY) then
                RawDeleteCell(GetID(mouseGridX, mouseGridY))
            end
        end
    end
    buttons[3].y = screenHeight - 50
    buttons[4].y = screenHeight - 50

    while buttons[3+#lists] do
        table.remove(buttons, 3+#lists)
    end
    if list == 1 then
        for i, v in ipairs(lists[1].cells) do
            if i == 1 then
                NewButton(tex[2], 40, screenHeight - (90 + 40*i), 2, 2, 0, function() cat = i end)
            end
            if i == 2 then
                NewButton(tex[15], 40, screenHeight - (90 + 40*i), 2, 2, 0, function() cat = i end)
            end
        end
    end
    if list == 2 then
        for i, v in ipairs(lists[2].cells) do
            if i == 1 then
                NewButton(tex[3], 120, screenHeight - (90 + 40*i), 2, 2, 0, function() cat = i end)
            end
            if i == 2 then
                NewButton(tex[1], 120, screenHeight - (90 + 40*i), 2, 2, 0, function() cat = i end)
            end
        end
    end
    if list == 1 and cat == 1 then
        for i, v in ipairs(cats.movers.cells) do
            NewButton(tex[v], (40 + 40*(i%cats.movers.max)), (screenHeight - 130)+math.floor(i/cats.movers.max), 2, 2, 0, function() selectCell(v) end)
        end
    end
    if list == 1 and cat == 2 then
        for i, v in ipairs(cats.pullers.cells) do
            NewButton(tex[v], (40 + 40*(i%cats.pullers.max)), (screenHeight - 170)+math.floor(i/cats.pullers.max), 2, 2, 0, function() selectCell(v) end)
        end
    end
    if list == 2 and cat == 1 then
        for i, v in ipairs(cats.pushables.cells) do
            NewButton(tex[v], (160 + 40*(i%cats.pushables.max)), (screenHeight - 130)+math.floor(i/cats.pushables.max), 2, 2, 0, function() selectCell(v) end)
        end
    end
    if list == 2 and cat == 2 then
        for i, v in ipairs(cats.walls.cells) do
            NewButton(tex[v], (120 + 40*(i%cats.walls.max)), (screenHeight - 170)+math.floor(i/cats.walls.max), 2, 2, 0, function() selectCell(v) end)
        end
    end
end

function love.load()
    screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    for x = 1, gridX do
        for y = 1, gridY do
            if x == 1 or x == gridX or y == 1 or y == gridY then
                PlaceCell(1, x, y, 0, false)
            end
        end
    end
    NewButton(tex[2], 50, 50, 4, 4, 0, function() simulate = true end)
    NewButton(tex[12], 125, 50, 4, 4, 0, function() resetGrid() end)
    NewButton(tex[2], 50, screenHeight - 50, 4, 4, 0, function() list = 1 end)
    NewButton(tex[3], 130, screenHeight - 50, 4, 4, 0, function() list = 2 end)
end