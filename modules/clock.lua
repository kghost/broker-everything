
-- module independent variables --
----------------------------------
local addon, ns = ...
local C, L, I = ns.LC.color, ns.L, ns.I


-- module own local variables and local cached functions --
-----------------------------------------------------------
local name = "Clock"; -- TIMEMANAGER_TITLE
local ttName,ttColumns, tt, module = name.."TT", 2;
local countries,month_short = {},{};
local played,initialized,clock_diff = false,false;
local _dateFormatValues = nil


-- register icon names and default files --
-------------------------------------------
I[name] = {iconfile="Interface\\Addons\\"..addon.."\\media\\clock"}; --IconName::Clock--


-- some local functions --
--------------------------
local function date(dateStr)
	local m = tonumber(_G.date("%m"));
	local M = _G["MONTH_".._G.date("%B"):upper()];
	if dateStr:find("_mm_") then
		dateStr = gsub(dateStr,"_mm_",M);
	end
	if dateStr:find("_m_") then
		dateStr = gsub(dateStr,"_m_",_G.date("%b."));
	end
	return _G.date(dateStr);
end

local function createTooltip(tt,update)
	if (tt) and (tt.key) and (tt.key~=ttName) then return end -- don't override other LibQTip tooltips...
	local h24 = ns.profile[name].format24;
	local dSec = ns.profile[name].showSeconds;
	local pT,pL,pS = ns.LT.GetPlayedTime();

	if tt.lines~=nil then tt:Clear(); end
	tt:AddHeader(C("dkyellow",TIMEMANAGER_TITLE));
	tt:AddSeparator();

	if ns.profile[name].showDate then
		tt:AddLine(C("ltyellow",L["Date"]),		C("white",date(ns.profile[name].dateFormat)));
	end
	tt:AddLine(C("ltyellow",L["Local time"]),	C("white",ns.LT.GetTimeString("LocalTime",h24,dSec)));
	tt:AddLine(C("ltyellow",L["Realm time"]),	C("white",ns.LT.GetTimeString("GameTime",h24,dSec)));
	tt:AddLine(C("ltyellow",L["UTC time"]),		C("white",ns.LT.GetTimeString("UTCTime",h24,dSec)));

	--tt:AddSeparator(3,0,0,0,0);
	--tt:AddLine(C("ltblue",L["Additional time zones"]));
	--tt:AddSeparator();
	--tt:AddLine(C("gray","coming soon"));

	tt:AddSeparator(3,0,0,0,0);
	tt:AddLine(C("ltblue",L["Playtime"]));
	tt:AddSeparator();
	tt:AddLine(C("ltyellow",TOTAL),C(pT and "white" or "gray",pT and SecondsToTime(pT) or "requested..."));
	tt:AddLine(C("ltyellow",LEVEL),C(pL and "white" or "gray",pL and SecondsToTime(pL) or "requested..."));
	tt:AddLine(C("ltyellow",L["Session"]),C("white",SecondsToTime(pS)));

	if ns.profile.GeneralOptions.showHints then
		tt:AddSeparator(3,0,0,0,0)
		ns.ClickOpts.ttAddHints(tt,name);
	end
	if not update then
		ns.roundupTooltip(tt);
	end
end

local function updater(self)
	local obj = ns.LDB:GetDataObjectByName(module.ldbName);
	local h24 = ns.profile[name].format24;
	local dSec = ns.profile[name].showSeconds;
	obj.text = ns.profile[name].timeLocal and ns.LT.GetTimeString("LocalTime",h24,dSec) or ns.LT.GetTimeString("GameTime",h24,dSec)
	if tt~=nil and tt.key==name.."TT" and tt:IsShown() then
		createTooltip(tt,true);
	end
end

local function dateFormatValues()
	if not _dateFormatValues then
		_dateFormatValues = {};
		for key,value in pairs({
			["%Y-%m-%d"] = "yyyy-mm-dd",
			["%Y.%m.%d"] = "yyyy.mm.dd",
			["%Y.%d.%m"] = "yyyy.dd.mm",
			["%d.%m.%Y"] = "dd.mm.yyyy",
			["%d/%m/%Y"] = "dd/mm/yyyy",
			["%m/%d/%Y"] = "mm/dd/yyyy",
			["%d. _mm_ %Y"] = "dd. mmmm yyyy",
			["%d. _mm_ %y"] = "dd. mmmm yy",
			["%d. _m_ %Y"] = "dd. mmm yyyy",
			["%Y _mm_ %d."] = "yyyy mm dd.",
		})do
			_dateFormatValues[key] = date(key)..C("ltgray"," ("..value..")");
		end
	end
	return _dateFormatValues;
end

-- module functions and variables --
------------------------------------
module = {
	events = {"PLAYER_LOGIN","TIME_PLAYED_MSG"},
	updateinterval = 1,
	timeout = 30,
	config_defaults = {
		format24 = true,
		timeLocal = true,
		showSeconds = false,
		showDate = true,
		dateFormat = "%Y-%m-%d"
	},
	clickOptionsRename = {
		["timemanager"] = "1_timemanager",
		["time"] = "2_toggle_time",
		["calendar"] = "3_calendar",
		["hoursmode"] = "4_hours_mode",
		["menu"] = "5_open_menu"
	},
	clickOptions = {
		["timemanager"] = {"Time manager","call","ToggleTimeManager"}, -- L["Open time manager"]
		["time"] = {"Switch (local or realm time)","module","switchTime"}, -- L["Switch (local or realm time)"]
		["calendar"] = {"Calendar","call","ToggleCalendar"}, -- L["Calendar"]
		["hoursmode"] = {"Switch (12 or 24 hours)","module","switchHoursMode"}, -- L["Switch (12 or 24 hours)"]
		["menu"] = "OptionMenu"
		-- open blizzards stopwatch?
	}
}

ns.ClickOpts.addDefaults(module,{
	timemanager = "_LEFT",
	calendar = "SHIFTRIGHT",
	hoursmode = "SHIFTLEFT",
	time = "_RIGHT",
	menu = "__NONE"
});

function module.switchTime()
	ns.profile[name].timeLocal = not ns.profile[name].timeLocal;
end

function module.switchHoursMode()
	ns.profile[name].format24 = not ns.profile[name].format24;
end


function module.options()
	return {
		broker = {
			timeLocal={ type="toggle", order=1, name=L["Local or realm time"], desc=L["Switch between local and realm time in broker button"] },
		},
		tooltip = {
			showSeconds={ type="toggle", order=1, name=L["Show seconds"], desc=L["Display the time with seconds in broker button and tooltip"] },
			showDate={ type="toggle", order=2, name=L["Show date"], desc=L["Display date in tooltip"] },
		},
		misc = {
			format24={ type="toggle", order=1, name=TIMEMANAGER_24HOURMODE, desc=L["Switch between time format 24 hours and 12 hours with AM/PM"] },
			dateFormat={ type="select", order=2, name=L["Date format"], desc=L["Choose your favorite date format"], values=dateFormatValues, width="double" },
		},
	}
end

-- function module.init() end

function module.onevent(self,event,...)
	if event=="BE_UPDATE_CFG" then
		ns.ClickOpts.update(name);
	elseif event=="PLAYER_LOGIN" then
		C_Timer.NewTicker(module.updateinterval,updater);
	elseif event=="TIME_PLAYED_MSG" then
		played = true
	end
end

-- function module.optionspanel(panel) end
-- function module.onmousewheel(self,direction) end

function module.ontimeout(self)
	if played==false then
		--RequestTimePlayed()
	end
end

-- function module.ontooltip(tt) end

function module.onenter(self)
	if (ns.tooltipChkOnShowModifier(false)) then return; end
	tt = ns.acquireTooltip({ttName, ttColumns , "LEFT", "RIGHT"},{true},{self})
	createTooltip(tt);
end

-- function module.onleave(self) end
-- function module.ondblclick(self,button) end


-- final module registration --
-------------------------------
ns.modules[name] = module;
