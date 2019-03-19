local ContainerFramework = {}

ContainerFramework.scriptName = "ContainerFramework"

ContainerFramework.defaultConfig = {
    storage = {
        cell = "Character Stuff Wonderland",
        location = {
            posX = 0,
            posY = 0,
            posZ = 0,
            rotX = 0,
            rotY = 0,
            rotZ = 0
        }
    }
}
ContainerFramework.config = DataManager.loadConfiguration(ContainerFramework.scriptName, ContainerFramework.defaultConfig)

ContainerFramework.defaultData = {
    recordData = {},
    instanceData = {}
}

ContainerFramework.recordData = {}
ContainerFramework.containerRecords = {}
ContainerFramework.guiseRecords = {}

ContainerFramework.instanceData = {}
ContainerFramework.containerInstances = {}
ContainerFramework.guiseInstances = {}

ContainerFramework.storageCell = nil


function ContainerFramework.createRecord(
    containerRefId,
    containerPacketType,
    guiseRefId,
    guisePacketType,
    collision
)
    local recordData = {
        container = {
            refId = containerRefId,
            type = containerPacketType
        }
    }
    
    local recordId = #ContainerFramework.recordData + 1
    ContainerFramework.recordData[recordId] = recordData
    
    ContainerFramework.containerRecords[recordData.container.refId] = recordId

    if guiseRefId ~= nil then
        if collision == nil then
            recordData.collision = false
        else
            recordData.collision = collision
        end
        
        recordData.guise = {
            refId = guiseRefId,
            type = guisePacketType
        }
        
        ContainerFramework.guiseRecords[recordData.guise.refId] = recordId
        
        if recordData.collision then
            table.insert(config.enforcedCollisionRefIds, recordData.guise.refId)
            local player = tableHelper.getAnyValue(Players)
            if player ~= nil then
                logicHandler.SendConfigCollisionOverrides(player.pid, true)
            end
        end
    end
    
    return recordId
end

function ContainerFramework.removeRecord(recordid)
    local recordData = ContainerFramework.recordData[recordId]
    
    if recordData ~= nil then
        ContainerFramework.containerRecords[recordData.container.refId] = nil
        
        if recordData.guise ~= nil then
            ContainerFramework.guiseRecords[recordData.guise.refId] = nil
            
            if recordData.collision then
                tableHelper.removeValue(config.enforcedCollisionRefIds, recordData.guise.refId)
            end
        end
        
        ContainerFramework.recordData[recordId] = nil
    end
end

function ContainerFramework.getRecordData(recordId)
    return ContainerFramework.recordData[recordId]
end


ContainerFramework.typeToPacketType = {
    armor = "place",
    book = "place",
    clothing = "place",
    creature = "spawn",
    miscellaneous = "place",
    npc = "spawn",
    potions = "place",
    weapon = "place"
}

function ContainerFramework.getPacketType(recordType)
    return ContainerFramework.typeToPacketType[recordType]
end

function ContainerFramework.createContainerAtLocation(recordId, cellDescription, location)
    local recordData = ContainerFramework.recordData[recordId]
    
    local instanceData = {
        recordId = recordId,
        container = {}
    }
    
    local instanceId = #ContainerFramework.instanceData + 1
    
    instanceData.container.cellDescription = ContainerFramework.config.storage.cell
    
    instanceData.container.uniqueIndex = logicHandler.CreateObjectAtLocation(
        ContainerFramework.config.storage.cell,
        ContainerFramework.config.storage.location,
        recordData.container.refId,
        recordData.container.type
    )
    
    ContainerFramework.containerInstances[instanceData.container.uniqueIndex] = instanceId
    
    if recordData.guise ~= nil then
        instanceData.guise = {}
        instanceData.guise.cellDescription = cellDescription
        
        instanceData.guise.uniqueIndex = logicHandler.CreateObjectAtLocation(
            cellDescription,
            location,
            recordData.guise.refId,
            recordData.guise.type
        )
        
        ContainerFramework.guiseInstances[instanceData.guise.uniqueIndex] = instanceId
    end
    
    ContainerFramework.instanceData[instanceId] = instanceData

    return instanceId
end

function ContainerFramework.removeObject(uniqueIndex, cellDescription)
    local tempLoad = false
    local cell = LoadedCells[cellDescription]
    if cell == nil then
        tempLoad = true
        logicHandler.LoadCell(cellDescription)
        cell = LoadedCells[cellDescription]
    end

    if cell.data.objectData[uniqueIndex] ~= nil then
        if next(Players) ~= nil then
            logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
        end

        cell.data.objectData[uniqueIndex] = nil
        cell:Save()
    end

    if tempLoad then
        logicHandler.UnloadCell(cellDescription)
    end
end

function ContainerFramework.removeContainer(instanceId)
    local instanceData = ContainerFramework.instanceData[instanceId]

    ContainerFramework.removeObject(
        instanceData.container.uniqueIndex,
        instanceData.container.cellDescription
    )
        
    if instanceData.guise ~= nil then
        ContainerFramework.removeObject(
            instanceData.guise.uniqueIndex,
            instanceData.guise.cellDescription
        )

        ContainerFramework.guiseInstances[instanceData.guise.uniqueIndex] = nil
    end

    ContainerFramework.containerInstances[instanceData.container.uniqueIndex] = nil

    ContainerFramework.instanceData[instanceId] = nil

    return true
end


function ContainerFramework.getInstanceData(instanceId)
    return ContainerFramework.instanceData[instanceId]
end

function ContainerFramework.getInventory(instanceId)
    local instanceData = ContainerFramework.getInstanceData(instanceId)
    return ContainerFramework.storageCell.data.objectData[instanceData.container.uniqueIndex].inventory
end

function ContainerFramework.setInventory(instanceId, inventory)
    local instanceData = ContainerFramework.getInstanceData(instanceId)
    ContainerFramework.storageCell.data.objectData[instanceData.container.uniqueIndex].inventory = inventory
end

function ContainerFramework.updateInventory(pid, instanceId)
    local instanceData = ContainerFramework.getInstanceData(instanceId)
    ContainerFramework.storageCell:LoadContainers(
        pid,
        ContainerFramework.storageCell.data.objectData,
        {instanceData.container.uniqueIndex}
    )
end


function ContainerFramework.checkConfig()
    if not config.allowOnContainerForUnloadedCells then
        tes3mp.LogMessage(
            enumerations.log.WARN,
            "[ContainerFramework] For this script to function properly, you need to set allowOnContainerForUnloadedCells to true in your config.lua\n"
        )
        return false
    end
    return true
end

function ContainerFramework.loadData()
    local data = DataManager.loadData(ContainerFramework.scriptName, ContainerFramework.defaultData)
    
    ContainerFramework.recordData = data.recordData
    for recordId, recordData in pairs(ContainerFramework.recordData) do
        ContainerFramework.containerRecords[recordData.container.refId] = recordId
        if recordData.guise ~= nil then
            ContainerFramework.containerRecords[recordData.guise.refId] = recordId
            
            if recordData.collision then
                table.insert(config.enforcedCollisionRefIds, recordData.guise.refId)
            end
        end
    end
    
    ContainerFramework.instanceData = data.instanceData
    for instanceId, instanceData in pairs(ContainerFramework.instanceData) do
        ContainerFramework.containerInstances[instanceData.container.uniqueIndex] = instanceId
        if instanceData.guise ~= nil then
            ContainerFramework.guiseInstances[instanceData.guise.uniqueIndex] = instanceId
        end
    end
end

function ContainerFramework.saveData()
    DataManager.saveData(ContainerFramework.scriptName, {
        recordData = ContainerFramework.recordData,
        instanceData = ContainerFramework.instanceData,
    })
end

function ContainerFramework.loadStorageCell()
    logicHandler.LoadCell(ContainerFramework.config.storage.cell)
    ContainerFramework.storageCell = LoadedCells[ContainerFramework.config.storage.cell]
end

function ContainerFramework.unloadStorageCell()
    logicHandler.UnloadCell(ContainerFramework.config.storage.cell)
    ContainerFramework.storageCell = nil
end


function ContainerFramework.OnServerPostInit()
    if not ContainerFramework.checkConfig() then
        return
    end
    ContainerFramework.loadData()
    ContainerFramework.loadStorageCell()
end

function ContainerFramework.OnServerExit()
    ContainerFramework.saveData()
    ContainerFramework.unloadStorageCell()
end

function ContainerFramework.OnPlayerAuthentified(eventStatus, pid)
    ContainerFramework.storageCell:LoadInitialCellData(pid)
end

function ContainerFramework.OnObjectActivateValidator(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if ContainerFramework.guiseInstances[object.uniqueIndex] ~= nil then
            local instanceId = ContainerFramework.guiseInstances[object.uniqueIndex]
            local instanceData = ContainerFramework.getInstanceData(instanceId)

            ContainerFramework.updateInventory(pid, instanceId)

            logicHandler.ActivateObjectForPlayer(
                pid,
                ContainerFramework.config.storage.cell,
                instanceData.container.uniqueIndex
            )
            
            return customEventHooks.makeEventStatus(false, nil)
        end
    end
end


function ContainerFramework.OnContainerValidator(eventStatus, pid, cellDescription, objects)
    for _, object in pairs(objects) do
        if ContainerFramework.containerInstances[object.uniqueIndex] ~= nil then
            local instanceId = ContainerFramework.containerInstances[object.uniqueIndex]
            return customEventHooks.triggerValidators(
                "ContainerFramework_OnContainer",
                {pid, instanceId}
            )
        end
    end
end

function ContainerFramework.OnContainerHandler(eventStatus, pid, cellDescription, objects)
    if not eventStatus.validCustomHandlers then
        return
    end

    for _, object in pairs(objects) do
        if ContainerFramework.containerInstances[object.uniqueIndex] ~= nil then
            local instanceId = ContainerFramework.containerInstances[object.uniqueIndex]
            customEventHooks.triggerHandlers(
                "ContainerFramework_OnContainer",
                eventStatus,
                {pid, instanceId}
            )
        end
    end
end


customEventHooks.registerHandler("OnServerPostInit", ContainerFramework.OnServerPostInit)
customEventHooks.registerHandler("OnServerExit", ContainerFramework.OnServerExit)
customEventHooks.registerHandler("OnPlayerAuthentified", ContainerFramework.OnPlayerAuthentified)

customEventHooks.registerValidator("OnObjectActivate", ContainerFramework.OnObjectActivateValidator)

customEventHooks.registerValidator("OnContainer", ContainerFramework.OnContainerValidator)
customEventHooks.registerHandler("OnContainer", ContainerFramework.OnContainerHandler)

ContainerFramework.commandStatus = {}

return ContainerFramework