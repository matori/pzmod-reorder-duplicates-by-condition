local ORDER_ASC = 'ASC'
local ORDER_DESC = 'DESC'

local CONDITION = 'condition'
local REMAINING = 'remaining'
local HUNGER_REDUCTION = 'hungerReduction'
local CALORIES = 'calories'
local DIRTINESS = 'dirtiness'
local BLOODINESS = 'bloodiness'

local menuTextByCondition = getText('ContextMenu_ReorderDuplicatesByCondition_ByCondition')
local menuTextByRemaining = getText('ContextMenu_ReorderDuplicatesByCondition_ByRemaining')
local menuTextByHungerReduction = getText('ContextMenu_ReorderDuplicatesByCondition_ByHungerReduction')
local menuTextByCalories = getText('ContextMenu_ReorderDuplicatesByCondition_ByCalories')
local menuTextByBloodiness = getText('ContextMenu_ReorderDuplicatesByCondition_ByBloodiness')
local menuTextByDirtiness = getText('ContextMenu_ReorderDuplicatesByCondition_ByDirtiness')

local menuTextHighToLow1 = getText('ContextMenu_ReorderDuplicatesByCondition_HighToLow1')
local menuTextLowToHigh1 = getText('ContextMenu_ReorderDuplicatesByCondition_LowToHigh1')
local menuTextHighToLow2 = getText('ContextMenu_ReorderDuplicatesByCondition_HighToLow2')
local menuTextLowToHigh2 = getText('ContextMenu_ReorderDuplicatesByCondition_LowToHigh2')
local menuTextHighToLow3 = getText('ContextMenu_ReorderDuplicatesByCondition_HighToLow3')
local menuTextLowToHigh3 = getText('ContextMenu_ReorderDuplicatesByCondition_LowToHigh3')

local sayTextAlreadyInOrder = getText('IGUI_ReorderDuplicatesByCondition_AlreadyInOrder')

local optionTextCharacterSpeaks = getText('UI_ReorderDuplicatesByCondition_CharacterSpeaks')
local optionTextCharacterSpeaksTooltip = getText('UI_ReorderDuplicatesByCondition_CharacterSpeaks_Tooltip')
local optionTextBloodinessDirtiness = getText('UI_ReorderDuplicatesByCondition_BloodinessDirtiness')
local optionTextBloodinessDirtinessTooltip = getText('UI_ReorderDuplicatesByCondition_BloodinessDirtiness_Tooltip')

local ReorderDuplicatesOptions = {
    showMessage = true,
    enableClothingSubParams = true,
}

local function createItemsTableValue(index, item, itemType)
    local itemData = { index = index, item = item }
    if itemType.isWeapon or itemType.isClothing then
        itemData[CONDITION] = item:getCondition()
    elseif itemType.isDrainable then
        itemData[REMAINING] = item:getUsedDelta()
    elseif itemType.isFood then
        local value = item:getHungerChange()
        itemData[HUNGER_REDUCTION] = math.abs(value)
        itemData[CALORIES] = item:getCalories()
    end
    if itemType.isClothing then
        itemData[DIRTINESS] = item:getDirtyness()
    end
    if itemType.isBloodClothing or itemType.isWeapon then
        itemData[BLOODINESS] = item:getBloodLevel()
    end
    return itemData
end

local function getItemsFromExpanded(selectedItems, itemType)
    local result = {}
    local firstItemName = selectedItems[1]:getName()

    for index, item in ipairs(selectedItems) do
        if not instanceof(item, 'InventoryItem') then
            break
        end
        local currentItemName = item:getName()
        if firstItemName ~= currentItemName then
            result = {}
            break
        end
        local itemTable = createItemsTableValue(index, item, itemType)
        table.insert(result, itemTable)
    end

    return result
end

local function getItemsFromCollapsed(selectedItems, itemType)
    local result = {}

    -- first item is dummy. it is same as second item.
    for i = 1, #selectedItems - 1 do
        local i1 = i + 1
        local item = selectedItems[i1]
        local itemTable = createItemsTableValue(i, item, itemType)
        table.insert(result, itemTable)
    end

    return result
end

local function getItemType(item)
    return {
        isWeapon = item:IsWeapon(),
        isDrainable = item:IsDrainable(),
        isClothing = item:IsClothing(),
        isFood = item:IsFood(),
        isBloodClothing = item:getBloodClothingType() ~= nil and (item:IsClothing() or item:IsInventoryContainer()),
    }
end

local function checkValidItemType(itemType)
    local isValid = false
    for _, value in pairs(itemType) do
        if value then
            isValid = true
            break
        end
    end
    return isValid
end

local function checkEnablingContextMenu(items, itemType, inventory, container)
    return #items > 1 and checkValidItemType(itemType) and inventory ~= container
end

local function canSeeCalories(playerObj, item)
    local traits = playerObj:getCharacterTraits()
    if traits:contains('Nutritionist') or traits:contains('Nutritionist2') then
        --print('has nutritionist')
        return true
    end
    return item:isPackaged()
end

-- for table.sort
local function createCompare(key, order)
    if order == ORDER_ASC then
        return function(a, b) return a[key] < b[key] end
    elseif order == ORDER_DESC then
        return function(a, b) return a[key] > b[key] end
    end
end

-- items table managed by value
local function createReorderingData(items, key)
    local data = {}

    for index, item in pairs(items) do
        local value = item[key]
        if not data[value] then
            data[value] = {
                value = value,
                last = index,
                items = {},
            }
        end
        data[value].last = index
        table.insert(data[value].items, item)
    end

    return data
end

-- filter items that must be moved
local function createTransferItems(data, itemsCount)
    local transferItems = {}
    local previousLastIndex = 0
    for index, baseDataItems in ipairs(data) do
        for _, itemData in pairs(baseDataItems.items) do
            if itemData.index < previousLastIndex + 1 then
                if index > 1 then
                    table.insert(transferItems, itemData.item)
                end
            end
        end
        if #transferItems > 1 then
            previousLastIndex = itemsCount
        elseif previousLastIndex < baseDataItems.last then
            previousLastIndex = baseDataItems.last
        end
    end
    return transferItems
end

local function reorder(playerObj, items, order, inventory, container, orderKey)
    local baseData = createReorderingData(items, orderKey)

    local orderedData = {}
    for _, element in pairs(baseData) do
        table.insert(orderedData, element)
    end

    table.sort(orderedData, createCompare('value', order))

    local transferItems = createTransferItems(orderedData, #items)

    if #transferItems > 0 then
        for _, item in pairs(transferItems) do
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, container, inventory))
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, inventory, container))
        end
    else
        if ReorderDuplicatesOptions.showMessage then
            playerObj:Say(sayTextAlreadyInOrder)
        end
    end

end

-- create context menu
local function ReorderDuplicatesContextMenu(player, contextMenu, selectedItems)
    local playerObj = getSpecificPlayer(player)
    local inventory = playerObj:getInventory()
    local isCollapsedDuplicates = false

    if not instanceof(selectedItems[1], 'InventoryItem') then
        isCollapsedDuplicates = true
    end

    -- if multi-selected collapsed Duplicates row
    if isCollapsedDuplicates and #selectedItems > 1 then
        return
    end

    local items
    local itemType

    if isCollapsedDuplicates then
        itemType = getItemType(selectedItems[1].items[1])
        items = getItemsFromCollapsed(selectedItems[1].items, itemType)
    else
        itemType = getItemType(selectedItems[1])
        items = getItemsFromExpanded(selectedItems, itemType)
    end

    local container = items[1].item:getContainer()

    if not checkEnablingContextMenu(items, itemType, inventory, container) then
        return
    end

    -- clone items table
    local clone = {}
    for k, v in pairs(items) do
        clone[k] = v
    end

    if itemType.isWeapon or itemType.isClothing then
        table.sort(clone, createCompare(CONDITION, ORDER_DESC))
        if clone[1][CONDITION] == clone[#clone][CONDITION] then
            -- print('all same condition')
        else
            -- add context menu
            local option = contextMenu:addOption(menuTextByCondition)
            local subContextMenu = ISContextMenu:getNew(contextMenu)
            contextMenu:addSubMenu(option, subContextMenu);
            subContextMenu:addOption(menuTextHighToLow1, playerObj, reorder, items, ORDER_DESC, inventory, container, CONDITION)
            subContextMenu:addOption(menuTextLowToHigh1, playerObj, reorder, items, ORDER_ASC, inventory, container, CONDITION)
        end
    end

    if itemType.isWeapon or itemType.isBloodClothing then
        if ReorderDuplicatesOptions.enableClothingSubParams then
            if clone[1][BLOODINESS] ~= nil then
                table.sort(clone, createCompare(BLOODINESS, ORDER_DESC))
                if clone[1][BLOODINESS] == clone[#clone][BLOODINESS] then
                    -- print('all same bloodiness')
                else
                    -- add context menu
                    local option = contextMenu:addOption(menuTextByBloodiness)
                    local subContextMenu = ISContextMenu:getNew(contextMenu)
                    contextMenu:addSubMenu(option, subContextMenu);
                    subContextMenu:addOption(menuTextHighToLow3, playerObj, reorder, items, ORDER_DESC, inventory, container, BLOODINESS)
                    subContextMenu:addOption(menuTextLowToHigh3, playerObj, reorder, items, ORDER_ASC, inventory, container, BLOODINESS)
                end
            end

            if itemType.isClothing and clone[1][DIRTINESS] ~= nil then
                table.sort(clone, createCompare(DIRTINESS, ORDER_DESC))
                if clone[1][DIRTINESS] == clone[#clone][DIRTINESS] then
                    -- print('all same dirtiness')
                else
                    -- add context menu
                    local option = contextMenu:addOption(menuTextByDirtiness)
                    local subContextMenu = ISContextMenu:getNew(contextMenu)
                    contextMenu:addSubMenu(option, subContextMenu);
                    subContextMenu:addOption(menuTextHighToLow3, playerObj, reorder, items, ORDER_DESC, inventory, container, DIRTINESS)
                    subContextMenu:addOption(menuTextLowToHigh3, playerObj, reorder, items, ORDER_ASC, inventory, container, DIRTINESS)
                end
            end
        end
        return
    end

    if itemType.isDrainable then
        table.sort(clone, createCompare(REMAINING, ORDER_DESC))
        if clone[1][REMAINING] == clone[#clone][REMAINING] then
            -- print('all same condition')
        else
        -- add context menu
            local option = contextMenu:addOption(menuTextByRemaining)
            local subContextMenu = ISContextMenu:getNew(contextMenu)
            contextMenu:addSubMenu(option, subContextMenu);
            subContextMenu:addOption(menuTextHighToLow2, playerObj, reorder, items, ORDER_DESC, inventory, container, REMAINING)
            subContextMenu:addOption(menuTextLowToHigh2, playerObj, reorder, items, ORDER_ASC, inventory, container, REMAINING)
        end
        return
    end

    if itemType.isFood then
        -- hunger reduction
        table.sort(clone, createCompare(HUNGER_REDUCTION, ORDER_DESC))
        if clone[1][HUNGER_REDUCTION] == clone[#clone][HUNGER_REDUCTION] then
            -- print('all same hunger reduction')
        else
        -- add context menu
            local option = contextMenu:addOption(menuTextByHungerReduction)
            local subContextMenu = ISContextMenu:getNew(contextMenu)
            contextMenu:addSubMenu(option, subContextMenu);
            subContextMenu:addOption(menuTextHighToLow1, playerObj, reorder, items, ORDER_DESC, inventory, container, HUNGER_REDUCTION)
            subContextMenu:addOption(menuTextLowToHigh1, playerObj, reorder, items, ORDER_ASC, inventory, container, HUNGER_REDUCTION)
        end

        -- calories
        table.sort(clone, createCompare(CALORIES, ORDER_DESC))
        canSeeCalories(playerObj, items[1].item)
        if clone[1][CALORIES] == clone[#clone][CALORIES] then
            -- print('all same calories')
        else
            if canSeeCalories(playerObj, items[1].item) then
                -- add context menu
                local option = contextMenu:addOption(menuTextByCalories)
                local subContextMenu = ISContextMenu:getNew(contextMenu)
                contextMenu:addSubMenu(option, subContextMenu);
                subContextMenu:addOption(menuTextHighToLow1, playerObj, reorder, items, ORDER_DESC, inventory, container, CALORIES)
                subContextMenu:addOption(menuTextLowToHigh1, playerObj, reorder, items, ORDER_ASC, inventory, container, CALORIES)
            end
        end
        return
    end
end

Events.OnFillInventoryObjectContextMenu.Add(ReorderDuplicatesContextMenu)

-- Mod Options
local ModOptionsSettings = {
    options = {
      box1 = true,
      box2 = true,
    },
    names = {
      box1 = optionTextCharacterSpeaks,
      box2 = optionTextBloodinessDirtiness,
    },
    mod_id = 'ReorderDuplicatesByCondition',
    mod_shortname = 'Reorder Duplicates by Condition',
  }

-- Connecting the settings to the menu, so user can change them.
if ModOptions and ModOptions.getInstance then
    local settings = ModOptions:getInstance(ModOptionsSettings)
    local options1 = settings:getData('box1')
    local options2 = settings:getData('box2')

    options1.tooltip = optionTextCharacterSpeaksTooltip
    options2.tooltip = optionTextBloodinessDirtinessTooltip

    function options1:OnApplyInGame(value)
        ReorderDuplicatesOptions.showMessage = value
    end

    function options2:OnApplyInGame(value)
        ReorderDuplicatesOptions.enableClothingSubParams = value
    end

    function options1:onUpdate(value)
        ReorderDuplicatesOptions.showMessage = value
    end

    function options2:onUpdate(value)
        ReorderDuplicatesOptions.enableClothingSubParams = value
    end
end
