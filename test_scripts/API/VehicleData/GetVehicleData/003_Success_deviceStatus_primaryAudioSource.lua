---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0182-audio-source-am-fm-xm.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1) Mobile app sends GetVehicleData request with deviceStatus=true
-- 2) SDL transfers this request to HMI
-- 3) HMI responds with value from PrimaryAudioSource enum in deviceStatus.primaryAudioSource
-- SDL must:
-- 1) Process GetVehicleData response and transfer it to mobile
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local utils = require("user_modules/utils")

--[[ Local Variables ]]
local audioSources = {
  "NO_SOURCE_SELECTED",
  "CD",
  "BLUETOOTH_STEREO_BTST",
  "USB",
  "USB2",
  "LINE_IN",
  "IPOD",
  "MOBILE_APP",
  "AM",
  "FM",
  "XM",
  "DAB"
}

local rpc = {
  name = "GetVehicleData",
  params = {
    deviceStatus = true
  }
}

--[[ Local Functions ]]
local function processRPCSuccess(pAudioSource, self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  local vehicleDataValues = {
    deviceStatus = {
      primaryAudioSource = pAudioSource
    }
  }
  EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params)
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", vehicleDataValues )
    end)
  local responseParams = vehicleDataValues
  responseParams.success = true
  responseParams.resultCode = "SUCCESS"
  mobileSession:ExpectResponse(cid, responseParams)
  utils.wait(300)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, source in pairs(audioSources) do
  runner.Step("RPC " .. rpc.name .. " source " .. source, processRPCSuccess, { source })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
