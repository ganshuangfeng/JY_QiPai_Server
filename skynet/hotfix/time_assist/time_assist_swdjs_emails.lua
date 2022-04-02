--
-- Author: lyx
-- Date: 2018/3/10
-- Time: 15:07
-- 说明：测试
-- 使用方法：
--  call <service addr> exe_file "hotfix/fixtest.lua"
--

local skynet = require "skynet_plus"
local cluster = require "skynet.cluster"
local base = require "base"
local nodefunc = require "nodefunc"
local basefunc = require "basefunc"
require "normal_enum"
require "printfunc"

local DATA = base.DATA
local CMD = base.CMD
local PUBLIC=base.PUBLIC

-- 只支持精确到分钟级别的时间
local updater_dt = 60

local exec_date = 20190201
local exec_h = 9
local exec_m = 10


local function do_something1()

	print("do_something1 finish!!!")


	local data={
		email={
			type = "native",
			title = "实物大奖赛等你来战",
			sender = "系统",
			valid_time = 1736657298,
			data = "{content='本周六（3月23日21:00）实物大奖赛\\n　　第一名：小米电视机\\n　　第二名：新秀丽制造行李箱\\n　　第三名：小米手环\\n　　还有更多红包券等你来拿，机会不容错过！！！\\n\\n　　　　　　　　　　　　　　　　　鲸鱼斗地主运营部'}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"实物大奖赛")

end


local function do_something2()

	print("do_something1 finish!!!")


	local data={
		email={
			type = "native",
			title = "实物大奖赛等你来战",
			sender = "系统",
			valid_time = 1736657298,
			data = "{content='本周六（3月23日21:00）实物大奖赛\\n　　第一名：小米电视机\\n　　第二名：新秀丽制造行李箱\\n　　第三名：小米手环\\n　　还有更多红包券等你来拿，机会不容错过！！！\\n\\n　　　　　　　　　　　　　　　　　鲸鱼斗地主运营部'}",
		},
	}

	--全局邮件
	local errcode = skynet.call(DATA.service_config.email_service,"lua",
										"external_send_email",
										data,
										"系统",
										"实物大奖赛")

end

--执行具体活动的内容
function PUBLIC.update()

	local cur_time = os.time()
	local cur_h = tonumber(os.date("%H",cur_time))
	local cur_m = tonumber(os.date("%M",cur_time))
	local cur_s = tonumber(os.date("%S",cur_time))
	local cur_date = tonumber(os.date("%Y%m%d",cur_time))

	if cur_date >= 20190322 and cur_h>=19 and cur_m>=30 and do_something1 then
		
		do_something1()

		do_something1 = nil

	end

	if cur_date >= 20190323 and cur_h>=12 and cur_m>=0 then
		
		do_something2()

		if DATA.updater then
			DATA.updater:stop()
			DATA.updater = nil
		end

	end

end


return function()

	if not DATA.updater then
		DATA.updater = skynet.timer(updater_dt,function() PUBLIC.update() end)
		return "start ok !!!"
	end

	return "has started !!!"

end