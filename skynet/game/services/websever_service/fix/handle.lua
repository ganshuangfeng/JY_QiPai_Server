--
-- Created by lyx.
-- User: hare
-- Date: 2018/6/4
-- Time: 1:47
-- sczd 过滤器
--

local skynet = require "skynet_plus"
local cjson = require "cjson"
local basefunc = require "basefunc"
require "printfunc"

local hlib = require "websever_service.handle_lib"

-----------------------------------------------------------
-- 处理器函数映射： ret=返回值处理函数, svr=调用的服务, param=参数名数组

local cmd_defines = 
{
    exec       ={ret=hlib.encode_code ,svr="collect_service"},
    unblock_player     ={ret=hlib.encode_code ,svr="collect_service"},
    send_mail          ={ret=hlib.encode_code ,svr="collect_service"},
    broadcast          ={ret=hlib.encode_code ,svr="collect_service"},

    -- 礼券系统

    addGiftCouponData ={ret=hlib.encode_code ,svr="gift_coupon_center_service"},
    updateGiftCouponData ={ret=hlib.encode_code ,svr="gift_coupon_center_service"},

    addGiftCouponPlayer ={ret=hlib.encode_code ,svr="gift_coupon_center_service"},
    updateGiftCouponPlayer ={ret=hlib.encode_code ,svr="gift_coupon_center_service"},
    deleteGiftCouponPlayer ={ret=hlib.encode_code ,svr="gift_coupon_center_service"},
}

-----------------------------------------------------------

return hlib.handler(cmd_defines)