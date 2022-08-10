-- ROBLOX NOTE: no upstream

local CurrentModule = script.Parent
local SrcModule = CurrentModule.Parent
local Packages = SrcModule.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it

local convertDescriptorToString = require(SrcModule.convertDescriptorToString).default

describe("convertDescriptorToString", function()
	it("should return same value if provided string", function()
		jestExpect(convertDescriptorToString("foo")).toBe("foo")
	end)

	it("should return same value it provided number", function()
		jestExpect(convertDescriptorToString(1)).toBe(1)
	end)

	it("should return same value it provided nil", function()
		jestExpect(convertDescriptorToString(nil)).toBe(nil)
	end)

	it("should return function name", function()
		local function foo() end
		jestExpect(convertDescriptorToString(foo)).toEqual("foo")
	end)

	it('should return "[Function anonymous]" for anonymous function', function()
		local foo = function() end
		jestExpect(convertDescriptorToString(foo)).toEqual("[Function anonymous]")
	end)
end)

return {}
