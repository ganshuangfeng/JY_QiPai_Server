---- 砸金蛋 管理器 服务，负责 组织房间，管理等

local skynet = require "skynet_plus"
local base=require "base"
local basefunc = require "basefunc"
local nodefunc = require "nodefunc"
require "normal_enum"
require "printfunc"

local CMD=base.CMD
local PUBLIC=base.PUBLIC
local DATA=base.DATA

DATA.service_config = nil

--- 所有的人的数据
DATA.all_player_info = {}

--- 所有的空闲桌子的数量, key = room_id , value = 剩余桌子数量
DATA.free_table_room_map = {}
--- 繁忙的的 房间
--DATA.busy_table_room_map = {}

--- 总共的桌子数量
DATA.all_table_count = 0

--- 最少的桌子数量
local min_table_num = 20

---- 桌子过期需要的时间,单位秒
DATA.table_destory_need_time = 3600

---
DATA.room_service_path = "zajindan_room_service/zajindan_room_service"

local room_count_id=0
---- 创建砸金蛋房间id
local function create_room_id()
	room_count_id=room_count_id+1
	return "zjd_room_"..room_count_id
end

local dt = 5
--- 一个房间的桌子数量
local room_table_num=nil
---- 开房
local function new_room()
	local room_id=create_room_id()
	if room_id then
		--创建房间
		local ret,state = skynet.call( DATA.service_config.node_service ,"lua","create",nil,
						DATA.room_service_path,
						room_id,{  })
		if not ret then
			skynet.fail(string.format("zajindan_manager_service error:call  state:%s",state))
			return
		end
		if not room_table_num then
			local num=nodefunc.call(room_id,"get_free_table_num")
			if num=="CALL_FAIL" then
				skynet.fail(string.format("zajindan_manager_service error:call get_free_table_num room_id:%s",room_id))
				return
			else
				room_table_num=num
			end
		end
		DATA.free_table_room_map[room_id]=room_table_num
		DATA.all_table_count = DATA.all_table_count + room_table_num
	end
	-- body
end

local function new_table( _player_id , _player_name )
	local room_id
	for id,v in pairs(DATA.free_table_room_map) do
		if v > 0 then
			room_id=id
			break
		end
	end

	---- 没有房间就先创建
	if not room_id then
		new_room()
		for id,v in pairs(DATA.free_table_room_map) do
			if v > 0 then
				room_id=id
				break
			end
		end
	end

	DATA.free_table_room_map[room_id]=DATA.free_table_room_map[room_id]-1
	DATA.all_table_count=DATA.all_table_count-1
	--if DATA.free_table_room_map[room_id]==0 then
		--DATA.busy_table_room_map[room_id]=DATA.free_table_room_map[room_id]
		--DATA.free_table_room_map[room_id]=nil
	--end
	if DATA.all_table_count < min_table_num then
		new_room()
	end

	--创建桌子
	local t_num=nodefunc.call(room_id,"new_table",
								{	
									player_id = _player_id,
									player_name = _player_name,
								},
								{
									
								})
	return room_id,t_num
end

local function destroyRoom()
	
	if room_table_num and DATA.all_table_count>room_table_num*4 then
		for id,v in pairs(DATA.free_table_room_map) do
			if v==room_table_num then
				DATA.free_table_room_map[id]=nil
				DATA.all_table_count=DATA.all_table_count-room_table_num
				nodefunc.send(id,"destroy")
				if DATA.all_table_count<=room_table_num*2 then
					break
				end
			end
		end
	end
end


--- 获得玩家信息
function CMD.get_player_info(player_id)
	return DATA.all_player_info[player_id]
end

--- 获得or创建 砸金蛋房间
function CMD.get_or_create_zjd_room(player_id , player_name)
	if not DATA.all_player_info[player_id] or not DATA.all_player_info[player_id].room_id or not DATA.all_player_info[player_id].table_id then
		local room_id , table_id = new_table(player_id , player_name)
		DATA.all_player_info[player_id] = DATA.all_player_info[player_id] or {}
		DATA.all_player_info[player_id].room_id = room_id
		DATA.all_player_info[player_id].table_id = table_id
		DATA.all_player_info[player_id].player_name = player_name

		DATA.all_player_info[player_id].is_start_clear_timeout = false    -- 是否开始清理倒计时
		DATA.all_player_info[player_id].clear_timeout = DATA.table_destory_need_time

	end

	return DATA.all_player_info[player_id].room_id , DATA.all_player_info[player_id].table_id
end

--- 玩家登录
function CMD.player_login( player_id )
	if DATA.all_player_info[player_id] then
		DATA.all_player_info[player_id].is_start_clear_timeout = false
		DATA.all_player_info[player_id].clear_timeout = DATA.table_destory_need_time
	end
end

--- 玩家退出
function CMD.player_logout( player_id )
	if DATA.all_player_info[player_id] then
		DATA.all_player_info[player_id].is_start_clear_timeout = true
	end
end

local function update()
	local delete_vec = {}

	for player_id ,data in pairs(DATA.all_player_info) do
		if data.is_start_clear_timeout then
			data.clear_timeout = data.clear_timeout - dt

			--- 回收桌子
			if data.clear_timeout < 0 then
				delete_vec[#delete_vec + 1] = player_id
			end

		end
	end

	local is_return_table = false

	for key,player_id in ipairs(delete_vec) do
		is_return_table = true

		local room_id = DATA.all_player_info[player_id].room_id
		local table_id = DATA.all_player_info[player_id].table_id

		DATA.all_table_count=DATA.all_table_count+1
		DATA.free_table_room_map[room_id]=DATA.free_table_room_map[room_id]+1

		nodefunc.send( room_id , "return_table" , table_id )

		DATA.all_player_info[player_id] = nil
	end
	
	if is_return_table then
		destroyRoom()
	end
end


function CMD.start(_service_config)
	DATA.service_config = _service_config

	--- 一启动创建一个房间
	new_room()

	skynet.timer( dt , function() 
		update() 
	end)
end


-- 启动服务
base.start_service()
