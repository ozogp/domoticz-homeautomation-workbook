--[[
    electric_usage_house.lua
    Send, every minute, an HTTP Request (GET) to the Raspberry Pi running the volkszaehler.
    The volkszaehler response is a JSON string.
    Update the Electricity Usage House device (171, VirtualSensors,,General,kWh) values.

    Request Examples
    (ensure to replace the space by a plus sign in the url request)
    #data last minute
    requesturl = 'http://vz-ip-address/middleware.php/data/5b8ea2a0-b342-11e8-bec6-15c040e6d041.json?from=1+minutes+ago&to=now'
    #data now
    requesturl = 'http://vz-ip-address/middleware.php/data/5b8ea2a0-b342-11e8-bec6-15c040e6d041.json?from=now&to=now',

    Request Result JSON string
    {"version":"0.3","data":{"tuples":###,"uuid":"5b8ea2a0-b342-11e8-bec6-15c040e6d041","from":1536243168796,"to":1536243170351,"min":[1536243170351,926.0450147835],"max":[1536243170351,926.0450147835],"average":926.045,"consumption":0.4,"rows":2}}
    Obtain the power consumption from key data.average.
    The power consumption (Watt) is used by Domoticz to calculate the Energy (Wh)
    
    For testing, add 'every minute' to the timer and check the log file.
    Project: atHome
    Interpreter: dzVents, Timer
    See: athome.pdf
    Author: Robert W.B. Linn
    Version: 20190628
]]--

local URL_DOMOTICZ = 'http://rpi-ip-address:8080'
-- The request url uses from=1 minutes ago to to=now - Note: spaces to be replaced by plus signs in the url
local URL_VZREQUEST = 'http://vz-ip-address/middleware.php/data/5b8ea2a0-b342-11e8-bec6-15c040e6d041.json?from=1+minutes+ago&to=now'

-- ensure the httpResponse name is unique across all dzVents scripts!
-- use the scriptname without _ or blanks
local RES_VZREQUEST = 'electricusagehouse'

-- Idx of the devices
local IDX_ELECTRICUSAGEHOUSE = 171  -- Type=General, SubType=kWh
-- local IDX_POWERCONSUMPTION = 44  -- Type=Usage, SubType=Electric !NOT USED

return {
    -- active = true,
	on = {
		timer = {
			'every minute'
		},
		httpResponses = {
            RES_VZREQUEST
        }
	},
	execute = function(domoticz, item)
        -- if the timer is executed, then place http get request, which result is handled by the callback.
        if (item.isTimer) then
            domoticz.openURL({ url = URL_VZREQUEST, method = 'GET', callback = RES_VZREQUEST })
		end

		-- callback handling the url get request response
		-- the item.trigger is requited, because the electrichouse device is updated via HTTP (workaround) and not dzVents Lua script
        if (item.isHTTPResponse) and (item.trigger == RES_VZREQUEST) then
            -- for tests log the data requested (json string)
			-- domoticz.log(item.data)

            if (item.ok) then -- statusCode == 2xx
                
                -- POWER CONSUMPTION ! NOT USED - just an example
                -- parse the json string to get the average from key data.average
                -- local power = math.floor(tonumber(item.json.data.average))
                -- update the powerconsumption device (Watt)
                -- domoticz.devices(IDX_POWERCONSUMPTION).updateEnergy(power)

                -- ELECTRICUSAGE
                -- Solution dzvents lua function = NOT WORKING
                -- parse the json string to get the energy consumption from key data.consumption
                -- local energy = tonumber(item.json.data.consumption)
                -- update the electrichouse device (Watt, Wh)
                -- domoticz.devices(IDX_ELECTRICUSAGEHOUSE).updateElectricity(power, energy)
                
                -- WORKAROUND solution using HTTP API /json.htm?type=command&param=udevice&idx=IDX&nvalue=0&svalue=POWER;ENERGY
                -- POWER=W; ENERGY=Wh
                -- The device option "Energy read" is set to computed
                local power = math.floor(tonumber(item.json.data.average))
                domoticz.openURL({
                        url = '' .. URL_DOMOTICZ .. '/json.htm?type=command&param=udevice&idx=' .. IDX_ELECTRICUSAGEHOUSE .. '&nvalue=0&svalue=' ..  tostring(power) .. ';0',
                        method = 'GET'})

                domoticz.log('[INFO] Electric usage updated: ' .. power .. ' W, status:' .. tostring(item.statusCode), domoticz.LOG_INFO)

                domoticz.log('[INFO] WhToday: ' .. tostring(domoticz.devices(IDX_ELECTRICUSAGEHOUSE).WhToday), domoticz.LOG_INFO)
                domoticz.log('[INFO] WhTotal: ' .. tostring(domoticz.devices(IDX_ELECTRICUSAGEHOUSE).WhTotal), domoticz.LOG_INFO)
                domoticz.log('[INFO] WhActual: ' .. tostring(domoticz.devices(IDX_ELECTRICUSAGEHOUSE).WhActual), domoticz.LOG_INFO)

            end

            if not (item.ok) then -- statusCode != 2xx
                local message = '[ERROR] ' .. HTTPCALLBACKNAME .. ':' .. tostring(item.statusCode) .. ' ' .. msgbox.isnowdatetime(domoticz)
                domoticz.helpers.alertmsg(domoticz, domoticz.ALERTLEVEL_YELLOW, message)
                domoticz.log(message, domoticz.LOG_INFO)
            end
        end
	end
}


