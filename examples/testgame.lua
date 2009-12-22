package.path = '../?.lua;'..package.path
require "adventure"

Key = object:new("key", {description = "rusty old key",
longdescr = "A rusty old key, granting access to the outside world.",
pickup = function ()
	room.all.hall.door.left.locked = false
	print("You have the key!")
end,
putdown = function()
	room.all.hall.door.left.locked = true
	print("You put the key down!")
end})

--room.current = 
room:new('hall', {description = 'You are in a large hall. It has nice paintings.',
								door = {left = {destination = "outside",locked = true}},
								objects = {key = Key}})
room:new('outside', {forbidden = "You can't go outside! Get the key first!",
					description = 'You are standing on grass, outside the house.',
					door = {right = {destination = "hall"}},
					objects = {}})

ps1 = '? '

rungame()