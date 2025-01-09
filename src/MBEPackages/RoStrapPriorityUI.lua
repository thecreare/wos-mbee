-- Abstract UI ReplicatedPseudoInstance
-- @author Validark

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function _Load_Library_(Name)
	return require(script.Parent[Name])
end

local Color = _Load_Library_("Color")
local Debug = _Load_Library_("Debug")
local Tween = _Load_Library_("Tween")
local Typer = _Load_Library_("Typer")
local Enumeration = _Load_Library_("Enumeration")
local PseudoInstance = _Load_Library_("PseudoInstance")
local ReplicatedPseudoInstance = _Load_Library_("ReplicatedPseudoInstance")

local InBack = Enumeration.EasingFunction.InBack.Value
local OutBack = Enumeration.EasingFunction.OutBack.Value

local LocalPlayer, PlayerGui do
	if RunService:IsClient() then
		if RunService:IsServer() then
			PlayerGui = game:GetService("CoreGui")
		else
			repeat LocalPlayer = Players.LocalPlayer until LocalPlayer or not task.wait()
			repeat PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") until PlayerGui or not task.wait()
		end
	end
end

local Screen = Instance.new("ScreenGui", PlayerGui)
Screen.Name = "RoStrapPriorityUIs"
Screen.DisplayOrder = 2^31 - 2

local DialogBlur = Instance.new("BlurEffect")
DialogBlur.Size = 0
DialogBlur.Name = "RoStrapBlur"

local function SetDialogBlurParentToNil()
	DialogBlur.Parent = nil
end

-- NOTE: Enter()s automatically when Parented
return PseudoInstance:Register("RoStrapPriorityUI", {
	Storage = {};

	Internals = {
		Blur = function(self)
			DialogBlur.Parent = Lighting
			Tween(DialogBlur, "Size", 56, OutBack, self.ENTER_TIME, true)
		end;

		Unblur = function(self)
			Tween(DialogBlur, "Size", 0, InBack, self.ENTER_TIME, true, SetDialogBlurParentToNil)
		end;

		DISMISS_TIME = 75 / 1000 * 2;
		ENTER_TIME = 150 / 1000 * 2;
		SCREEN = Screen;
	};

	Events = { };

	Methods = {
		Enter = 0;
		Dismiss = 0;

		Destroy = function(self)
			self:Dismiss()
			self:super("Destroy")
		end;
	};

	Properties = {
		Parent = function(self, Parent)
			if Parent and PlayerGui then
				self:Enter()
				if self.SHOULD_BLUR then
					self:Blur()
				end
			end

			self:rawset("Parent", Parent)
		end;

		Dismissed = Typer.Boolean;
	};

	Init = function(self, ...)
		self:superinit(...)
	end;
}, ReplicatedPseudoInstance)
