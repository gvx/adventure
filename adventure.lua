pass = function() end

function newobject(class, name, table)
	local t = table or {}
	local name = name or #class.all
	setmetatable(t, {__index = class})
	class.all[name] = t
	t._name = name
	return t
end

room = {all = {}, enter = pass, leave = pass, description = '', current = nil}
function room:new(name, t)
	newobject(self, name, t)
	t.door = t.door or {}
	t.objects = t.objects or {}
	return t
end

object = {all = {}}
function object:new(name, t)
	newobject(self, name, t)
	t.action = t.action or {}
	return t
end

function getobj(param)
	local obj = room.current.objects[param]
	if obj then
		return obj
	end
	for k,obj in pairs(room.current.objects) do
		if obj.description:lower() == param then
			return obj
		end
	end
end
function getinvobj(param)
	for i,obj in ipairs(player.inventory) do
		if obj._name == param or obj.description:lower() == param then
			return obj, i
		end
	end
end

player = {inventory = {}}

function info()
	print(room.current.description)
end

function split(text)
	local t = {}
	local n = 1
	for v in string.gmatch(text, "([^ ]+)") do
       t[n] = v
	   n = n + 1
    end
	return t
end

actions = {}
if not _NODEFAULT then
	validate = {
	door = {"go through (.+)",
			"go (.+)",
			"use (.+)",
			"enter (.+)",
		   },
	use = {"use (.+)",
		  },
	talk = {"talk to (.+)",
			"talk (.+)",
		   },
	look = {"look at (.+)",
			"look (.+)",
			"describe (.+)",
			"examine (.+)",
		   },
	pickup = {"pick (.+) up",
			  "pick up (.+)",
			  "pick (.+)",
			  "take (.+)",
			  "get (.+)",
			 },
	putdown = {"put (.+) down",
			   "put down (.+)",
			   "put (.+)",
			   "drop (.+)",
			  },
	checkinventory = {"check inventory",
					  "check",
					  "list",
					 },
	}

	function actions.door(param)
		local newroomdir = room.current.door[param]
		if not newroomdir then
			for k,v in pairs(room.current.door) do
				if v.destination == param then
					newroomdir = v
					break
				end
			end
		end
		if newroomdir then
			local newroom = room.all[newroomdir.destination]
			if newroomdir.locked or newroom and newroom:enter() then
				if newroom.forbidden then
					print(newroom.forbidden)
				else
					print("You can't go there!")
				end
				return
			end
			room.current = newroom
			info()
		end
	end
	function actions.look(param)
		if param ~= 'around' and param ~= 'room' then
			local obj = getobj(param)
			
			if obj then
				if obj.longdescr then
					print(obj.longdescr)
				else
					print("A mysterious "..(obj.description or param))
				end
			else
				print("I see no "..param.." here.")
			end
		else
			info()
			print("You see:")
			for k,v in pairs(room.current.objects) do
				print('* '..(v.quant or 'a ')..(v.description or k))
			end
			print("Doors:")
			for k,v in pairs(room.current.door) do
				print('* '..k..' (leading to '..v.destination..')')
			end
		end
	end
	function actions.pickup(param)
		local obj = getobj(param)
		if obj then
			if obj.pickup and obj.pickup() then --veto if pickup() returns true
				return
			end
			table.insert(player.inventory, obj)
			room.current.objects[param] = nil
			print("You picked up "..(obj.description or param)..".")
		else
			print("I see no "..param.." here.")
		end
	end
	function actions.putdown(param)
		local obj, i = getinvobj(param)
		if obj then
			if obj.putdown and obj.putdown() then --veto if pickup() returns true
				return
			end
			table.remove(player.inventory, i)
			room.current.objects._name = obj
			print("You put "..(obj.description or param).." down.")
		else
			print("You have no "..param.." in your inventory.")
		end
	end
	function actions.checkinventory()
		if #player.inventory~=0 then
			print("In your inventory you find:")
			for k,v in pairs(player.inventory) do
				print('* '..(v.quant or 'a ')..(v.description or v._name))
			end
		else
			print("In your inventory you find nothing.")
		end
	end
else
	validate = {}
end

function fixvalids()
	for action,valids in pairs(validate) do
		for i,valid in ipairs(valids) do
			valids[i] = '^'..valid
		end
	end
end

function doaction(action, param)
	actions[action](param)
end

function parse(text)
	local text = text:lower()
	if text == 'exit' then return 'exit' end
	for action,valids in pairs(validate) do
		for i,valid in ipairs(valids) do
			local result = string.match(text, valid)
			if result then
				doaction(action, result)
				return
			end
		end
	end
	if notfoundhandler then
		notfoundhandler(text)
	end
end

function rungame()
	if gamename then print(gamename) end
	if gamedesc then print(gamedesc) end
	if not room.current then room.current = select(2, next(room.all)) end
	if not room.current then print("No rooms are loaded. Quitting...") return end
	info()
	local input
	local ps1 = ps1 or "> "
	local res
	while true do
		io.stdout:write(ps1)
		input = io.stdin:read()
		if not input then io.stdout:write('\n') return end
		res = parse(input)
		if res == 'exit' then return end
	end
end
