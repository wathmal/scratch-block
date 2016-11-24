



-- adc config
--if adc.force_init_mode(adc.INIT_VDD33)
--then
  --node.restart()
  --return -- don't bother continuing, the restart is scheduled
--end

-- connect to Wifi
wifi.setmode(wifi.STATION)
wifi.sta.config("DR", "Dula@0201")

-- MQTT Client configuration
m = mqtt.Client("user_id", 120, "", "")
m:on("connect", function(client) print ("connected to MQTT server!") end)
m:on("offline", function(client) print ("mqtt offline") end)

function mainloop()

end

function mqttcon()
    if wifi.sta.getip()== nil then
        print("ip unavailable, waiting...")
    else
    tmr.stop(1)
    m:connect("192.168.88.100", 1883, 0, 
function(client) 
print("connected to mqtt") end, 
function(client, reason) 
print("failed on MQTT due to : "..reason) end) 
tmr.alarm(2,500,1,mainloop)    
end
end

tmr.alarm(1,5000,1,mqttcon)



