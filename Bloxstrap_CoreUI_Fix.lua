local RAW = "https://raw.githubusercontent.com/new-qwertyui/Bloxstrap/main/"
local API = "https://api.github.com/repos/new-qwertyui/Bloxstrap/contents/"
local hidegui = getgenv().hideui or false

local cloneref = cloneref or function(...)
    return ...
end

local HttpService = cloneref(game:GetService("HttpService"))

local function mkdir(path)
    if makefolder and not isfolder(path) then
        pcall(makefolder, path)
    end
end

mkdir("Bloxstrap")
mkdir("Bloxstrap/Main")
mkdir("Bloxstrap/Main/Functions")
mkdir("Bloxstrap/Main/Configs")
mkdir("Bloxstrap/Main/Fonts")
mkdir("Bloxstrap/Images")

local function installMissing()
    if not isfile("Bloxstrap/Main/Functions/GuiLibrary.lua") then
        local list = HttpService:JSONDecode(
            game:HttpGet(API .. "Main/Functions", true)
        )

        for _, v in ipairs(list) do
            if v.name and v.name:find("%.lua$") then
                writefile(
                    "Bloxstrap/Main/Functions/" .. v.name,
                    "return loadstring(game:HttpGet('" ..
                    RAW ..
                    "Main/Functions/" ..
                    v.name ..
                    "', true))()"
                )
            end
        end
    end

    if not isfile("Bloxstrap/Main/Configs/Default.json") then
        writefile(
            "Bloxstrap/Main/Configs/Default.json",
            "{}"
        )
    end
end

installMissing()

local source = game:HttpGet(
    RAW .. "Main/Bloxstrap.lua",
    true
)

local startMarker =
    "local funnycon\nlocal guisets = {}"

local endMarker =
    "local touchuuval = 1.2"

local startPos =
    string.find(
        source,
        startMarker,
        1,
        true
    )

local endPos =
    startPos and string.find(
        source,
        endMarker,
        startPos,
        true
    )

if not startPos or not endPos then
    error(
        "GUIScaler block not found. Bloxstrap was probably updated."
    )
end

local patched = [=[

local funnycon
local funnycorecon

local guisets = {}
local guisetmap = {}

local positionsets = {}
local positionmap = {}

local CORE_SCALE_TAG =
    "__BloxstrapCoreUIScaleFix"

local CORE_SCALE = 0.7

local function rememberScale(
    scaler,
    oldscale,
    created
)

    if not scaler
        or guisetmap[scaler]
    then
        return
    end

    guisetmap[scaler] = true

    table.insert(
        guisets,
        {
            oldscale = oldscale,
            scaler = scaler,
            created = created
        }
    )
end

local function rememberPosition(gui)

    if not gui
        or positionmap[gui]
    then
        return
    end

    positionmap[gui] = true

    table.insert(
        positionsets,
        {
            gui = gui,
            position = gui.Position
        }
    )
end

local function getOriginalPosition(gui)

    for _, data in ipairs(positionsets) do
        if data.gui == gui then
            return data.position
        end
    end

    return nil
end

local function setPositionOffset(
    gui,
    x,
    y
)

    if not gui
        or not gui:IsA("GuiObject")
    then
        return
    end

    rememberPosition(gui)

    local original =
        getOriginalPosition(gui)

    if not original then
        return
    end

    gui.Position =
        UDim2.new(
            original.X.Scale,
            original.X.Offset + x,
            original.Y.Scale,
            original.Y.Offset + y
        )
end

local function scalePlayerGui(v)

    if not v
        or v.Name == "TouchGui"
    then
        return
    end

    local oldui =
        v:FindFirstChildWhichIsA(
            "UIScale",
            true
        )

    if oldui then

        rememberScale(
            oldui,
            oldui.Scale,
            false
        )

        oldui.Scale = 0.5

    else

        local uiscale =
            Instance.new("UIScale")

        uiscale.Scale = 0.7
        uiscale.Parent = v

        rememberScale(
            uiscale,
            9e9,
            true
        )
    end
end

local function directScale(target)

    if not target
        or not target:IsA("GuiObject")
    then
        return CORE_SCALE
    end

    local existingFix =
        target:FindFirstChild(
            CORE_SCALE_TAG
        )

    if existingFix
        and existingFix:IsA("UIScale")
    then

        rememberScale(
            existingFix,
            9e9,
            true
        )

        existingFix.Scale =
            CORE_SCALE

        return existingFix.Scale
    end

    local oldui

    for _, child in ipairs(
        target:GetChildren()
    ) do

        if child:IsA("UIScale") then
            oldui = child
            break
        end
    end

    if oldui then

        rememberScale(
            oldui,
            oldui.Scale,
            false
        )

        oldui.Scale = 0.5

        return oldui.Scale
    end

    local uiscale =
        Instance.new("UIScale")

    uiscale.Name =
        CORE_SCALE_TAG

    uiscale.Scale =
        CORE_SCALE

    uiscale.Parent =
        target

    rememberScale(
        uiscale,
        9e9,
        true
    )

    return uiscale.Scale
end

local function findDescendant(
    root,
    name
)

    if not root then
        return nil
    end

    local direct =
        root:FindFirstChild(name)

    if direct then
        return direct
    end

    for _, v in ipairs(
        root:GetDescendants()
    ) do

        if v.Name == name then
            return v
        end
    end

    return nil
end

local function scaleBackpack(
    topbar,
    excludedRoot
)

    if not topbar then
        return
    end

    for _, v in ipairs(
        topbar:GetDescendants()
    ) do

        if v:IsA("ImageButton")
            or v:IsA("ImageLabel")
        then

            local name =
                string.lower(v.Name)

            local image =
                string.lower(
                    tostring(v.Image)
                )

            if
                string.find(
                    name,
                    "backpack",
                    1,
                    true
                )

                or string.find(
                    name,
                    "inventory",
                    1,
                    true
                )

                or string.find(
                    image,
                    "backpack",
                    1,
                    true
                )
            then

                local target = v
                local current = v.Parent

                while current
                    and current ~= topbar
                do

                    if current:IsA(
                        "GuiButton"
                    ) then

                        target = current
                    end

                    if excludedRoot
                        and current
                            == excludedRoot
                    then

                        target = nil
                        break
                    end

                    current =
                        current.Parent
                end

                if target
                    and target:IsA(
                        "GuiObject"
                    )
                then

                    directScale(target)
                end
            end
        end
    end
end

local function scaleCoreUI()

    local CoreGui =
        game:GetService("CoreGui")

    local topbar =
        CoreGui:FindFirstChild(
            "TopBarApp"
        )

    if topbar then

        local holder =
            findDescendant(
                topbar,
                "MenuIconHolder"
            )

        local left =
            findDescendant(
                topbar,
                "UnibarLeftFrame"
            )

        if holder
            and holder:IsA("GuiObject")
        then

            pcall(function()
                holder.ClipsDescendants =
                    false
            end)

            local trigger =
                findDescendant(
                    holder,
                    "TriggerPoint"
                )

            if trigger
                and trigger:IsA(
                    "GuiObject"
                )
            then

                pcall(function()
                    trigger.ClipsDescendants =
                        false
                end)
            end

            local icon =
                trigger
                and findDescendant(
                    trigger,
                    "IconHitArea"
                )

            if icon
                and icon:IsA("GuiObject")
            then

                directScale(icon)

                setPositionOffset(
                    holder,
                    0,
                    -4
                )

            else

                directScale(holder)

                setPositionOffset(
                    holder,
                    0,
                    -4
                )
            end
        end

        if left
            and left:IsA("GuiObject")
        then

            pcall(function()
                left.ClipsDescendants =
                    false
            end)

            directScale(left)

            if holder
                and holder:IsA(
                    "GuiObject"
                )
            then

                rememberPosition(left)

                local basePosition =
                    getOriginalPosition(
                        left
                    )

                if basePosition then

                    local shrink =
                        holder.AbsoluteSize.X
                        * (1 - CORE_SCALE)

                    local gap = 3

                    left.Position =
                        UDim2.new(
                            basePosition.X.Scale,
                            basePosition.X.Offset
                                - shrink
                                - gap,
                            basePosition.Y.Scale,
                            basePosition.Y.Offset
                        )
                end
            end

            scaleBackpack(
                topbar,
                left
            )

        else

            local unibar =
                findDescendant(
                    topbar,
                    "UnibarMenu"
                )

            if unibar
                and unibar:IsA(
                    "GuiObject"
                )
            then

                directScale(unibar)

                scaleBackpack(
                    topbar,
                    unibar
                )

            else

                scaleBackpack(
                    topbar,
                    nil
                )
            end
        end
    end

    local chat =
        CoreGui:FindFirstChild(
            "ExperienceChat"
        )

    if chat then

        local appLayout =
            findDescendant(
                chat,
                "appLayout"
            )

        if appLayout
            and appLayout:IsA(
                "GuiObject"
            )
        then

            directScale(appLayout)
        end
    end
end

local function restoreEverything()

    pcall(function()

        if funnycon then
            funnycon:Disconnect()
            funnycon = nil
        end
    end)

    pcall(function()

        if funnycorecon then
            funnycorecon:Disconnect()
            funnycorecon = nil
        end
    end)

    for _, v in ipairs(
        guisets
    ) do

        pcall(function()

            if v.scaler
                and v.scaler.Parent
            then

                if v.created
                    or v.oldscale == 9e9
                then

                    v.scaler:Destroy()

                else

                    v.scaler.Scale =
                        v.oldscale
                end
            end
        end)
    end

    for _, v in ipairs(
        positionsets
    ) do

        pcall(function()

            if v.gui
                and v.gui.Parent
            then

                v.gui.Position =
                    v.position
            end
        end)
    end

    table.clear(guisets)
    table.clear(positionsets)
    table.clear(guisetmap)
    table.clear(positionmap)
end

local guiscale =
    Appearance:AddToggle({

        Name = "GUIScaler",

        Description =
            "Decrease the roblox gui scales",

        Default =
            Bloxstrap.Config.GUIScale,

        Callback = function(call)

            Bloxstrap.UpdateConfig(
                "GUIScale",
                call
            )

            if call then

                funnycon =
                    lplr.PlayerGui.ChildAdded
                    :Connect(
                        function(v)

                            scalePlayerGui(v)
                        end
                    )

                for _, v in ipairs(
                    lplr.PlayerGui:GetChildren()
                ) do

                    scalePlayerGui(v)
                end

                scaleCoreUI()

                funnycorecon =
                    game:GetService(
                        "CoreGui"
                    )
                    .DescendantAdded
                    :Connect(
                        function()

                            task.defer(
                                function()

                                    task.wait(
                                        0.05
                                    )

                                    if
                                        Bloxstrap
                                        .Config
                                        .GUIScale
                                    then

                                        scaleCoreUI()
                                    end
                                end
                            )
                        end
                    )

            else

                restoreEverything()
            end
        end
    })

]=]

source =
    string.sub(
        source,
        1,
        startPos - 1
    )
    ..
    patched
    ..
    string.sub(
        source,
        endPos
    )

local chunk, err =
    loadstring(
        source,
        "Bloxstrap CoreUI Fix"
    )

if not chunk then
    error(err)
end

local Bloxstrap =
    chunk()

Bloxstrap.start()

Bloxstrap.Visible(
    not hidegui
)