--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]
-- ROBLOX NOTE: no upstream

local CurrentModule = script.Parent.Parent
local Packages = CurrentModule.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local describe = JestGlobals.describe
local beforeAll = JestGlobals.beforeAll

local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local extends = LuauPolyfill.extends

local AssertionError = LuauPolyfill.AssertionError

local alignedAnsiStyleSerializer = require(Packages.Dev.TestUtils).alignedAnsiStyleSerializer

local expect = require(CurrentModule)

describe("Lua toThrowMatcher tests", function()
	beforeAll(function()
		expect.addSnapshotSerializer(alignedAnsiStyleSerializer)
	end)

	local CustomError = extends(Error, "CustomError", function(self, message)
		self.message = message
		self.name = "Error"
		self.stack = "  at expect" .. " (packages/expect/src/__tests__/toThrowMatchers-test.js:24:74)"
	end)

	it("works well for single errors", function()
		expect(function()
			error("I am erroring!")
		end).toThrow("I am erroring!")

		expect(function()
			expect(function()
				error("I am erroring!")
			end).toThrow("I am erroring?")
		end).toThrow()
	end)

	local function error1()
		error(Error(""))
	end

	local function error2()
		error("")
	end

	local function test1()
		error1()
	end

	local function test2()
		error2()
	end

	local function error3()
		error(AssertionError.new({ message = "" }))
	end

	local function test3()
		error3()
	end

	it("prints the stack trace for Lua Error error", function()
		expect(function()
			expect(function()
				test1()
			end).never.toThrow()
		end).toThrowErrorMatchingSnapshot()
	end)

	it("prints the stack trace for Lua string error", function()
		expect(function()
			expect(function()
				test2()
			end).never.toThrow()
		end).toThrowErrorMatchingSnapshot()
	end)

	it("prints the stack trace for Lua string error 2", function()
		expect(function()
			expect(function()
				test2()
			end).toThrow("wrong information")
		end).toThrowErrorMatchingSnapshot()
	end)

	it("prints the stack trace for Lua AssertionError error", function()
		expect(function()
			expect(function()
				test3()
			end).never.toThrow()
		end).toThrowErrorMatchingSnapshot()
	end)

	it("matches Error", function()
		expect(function()
			error(Error("error msg"))
		end).toThrow(Error("error msg"))
		expect(function()
			error(CustomError("error msg"))
		end).toThrow(CustomError("error msg"))
		expect(function()
			error(CustomError("error msg"))
		end).toThrow(Error("error msg"))
		-- this would match in upstream Jest even though it is somewhat nonsensical
		expect(function()
			error(Error("error msg"))
		end).toThrow(CustomError("error msg"))
	end)

	it("matches empty Error", function()
		expect(function()
			error(Error())
		end).toThrow(Error())
	end)

	-- ROBLOX deviation: sanity check test case
	it("cleans stack trace and prints correct files", function()
		local function func2()
			-- this line should error
			return (nil :: any) + 1
		end

		-- 2 lines in stack trace
		expect(function()
			expect(function()
				func2()
			end).never.toThrow()
		end).toThrowErrorMatchingSnapshot()
	end)

	it("toThrow should fail if expected is a string and thrown message is a table", function()
		expect(function()
			expect(function()
				error({ message = { key = "value" } })
			end).toThrow("string")
		end).toThrowErrorMatchingSnapshot()
	end)

	local jest = require(Packages.Dev.JestGlobals).jest
	it("makes sure that jest.fn() is callable", function()
		local mock = jest.fn()
		expect(mock).never.toThrow()
	end)

	expect.extend({
		toErrorString = function(self)
			error("I am erroring!")
		end,
		toErrorTable = function(self)
			error({ message = "I am erroring!" })
		end,
	})

	it("works for custom throwing matchers that throw strings", function()
		expect(function()
			(expect(true) :: any).toErrorString()
		end).toThrow("I am erroring!")
	end)

	it("works for custom throwing matchers that throw tables", function()
		expect(function()
			(expect(true) :: any).toErrorTable()
		end).toThrow("I am erroring!")
	end)
end)
