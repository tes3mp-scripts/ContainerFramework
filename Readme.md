This module does nothing by itself, but provides an API to handle various types of custom containers.

Requires [DataManager](https://github.com/tes3mp-scripts/DataManager)!

Has to be `require`d before any of the modules that use it.

It is necessary to set `allowOnContainerForUnloadedCells = true` in `scripts/config.lua`.

You can find the configuration file in `server/data/custom/__config_ContainerFramework.json`.
* storage
  * `cell` cell, where the actual containers will be placed. Only set this to an unaccessible cell. It will be always kept loaded. If you are using any cell resetting scripts, put this cell to exceptions.
  * `location` at which containers will be spawned in the `cell`.

Using it in your modules
---
The following is a list of all functions in this module (and their arguments) you are expected to use in your scripts. If you required it in standard way, they will be accessible from the global `ContainerFramework` table.
* `createRecord`
  * `containerRefId` `refId` of the container spawned in `cell`
  * `containerPacketType` should be `spawn` for NPCs and creatures or `place` otherwise
  * `guiseRefId` `refId` of the object visually spawned at desired location
  * `guisePacketType` same as `containerPacketType`
  * `collision` whether `guise` should have collision
  *  returns `recordId`, which you can later use to spawn and manipulate containers. Expects any custom records to already exist.
* `removeRecord`
  * `recordId`
  * removes the record with given `recordId`. Does not remove custom records for given `refId`s.
* `getRecordData` 
  * `recordId`
  * returns
    ```Lua
    {
        container = {
            refId,
            type --packetType
        },
        guise = {
            refId,
            type --packetType
        },
        collision
    }
    ```
* `createContainer` creates a `container` in `cell`. Should be used for records with no `guise` set.
  * `recordId`
  * returns `instanceId` to be used with other functions later
* `createContainerAtLocation` same as `createContainer`, but also spawns the `guise` at specificied location
  * `recordId`
  * `cellDescription`
  * `location`
  * returns `instanceId`, same as `createContainer`
* `removeContainer` removes both the `guise` and `container`
  * `instanceId`
* `getInstanceData`
  * `instanceId`
  * returns
    ```Lua
    {
        recordId,
        container = {
            uniqueIndex,
            cellDescription, --should be the same as `cell` in the config file, unless changed
        },
        guise = {
            uniqueIndex,
            cellDescription
        }
    }
    ```
* `activateContainer` activates `container` from given instance for `pid`
  * `pid`
  * `instanceId`
* `getInventory` returns the inventory of `container`
  * `instanceid`
* `setInventory` changes inventory of `container` to given `inventory`
  * `instanceId`
  * `inventory`
* `updateinventory` sends necessary packets to `pid`
  * `pid`
  * `instanceId`

There are also an event you can catch:  
`ContainerFramework_OnContainer` with arguments `{pid, instanceId, index}`, where `index` is the index you need to use `tes3mp.GetContainer...` functions.  
Has both a Validator and a Handler.