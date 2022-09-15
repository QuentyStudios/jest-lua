--!nocheck
-- ROBLOX upstream: https://github.com/facebook/jest/blob/v27.4.7/packages/expect/src/__tests__/spyMatchers.test.ts
-- /**
-- * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
-- *
-- * This source code is licensed under the MIT license found in the
-- * LICENSE file in the root directory of this source tree.
-- */

local CurrentModule = script.Parent.Parent
local Packages = CurrentModule.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local describe = JestGlobals.describe
local it = JestGlobals.it
local beforeAll = JestGlobals.beforeAll

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Set = LuauPolyfill.Set

local alignedAnsiStyleSerializer = require(Packages.Dev.TestUtils).alignedAnsiStyleSerializer
local expect = require(CurrentModule)

local jestMock = require(Packages.Dev.JestMock).ModuleMocker

local function createSpy(fn)
	local spy = {}
	setmetatable(spy, {
		__call = function() end,
	})

	spy.calls = {
		all = function()
			return Array.map(fn.mock.calls, function(args)
				return { args = args }
			end)
		end,
		count = function()
			return #fn.mock.calls
		end,
	}

	return spy
end

-- For now, we are doing this instead of having a global namespace
local mock

beforeAll(function()
	mock = jestMock.new()
	expect.addSnapshotSerializer(alignedAnsiStyleSerializer)
end)

for _, called in ipairs({ "toBeCalled", "toHaveBeenCalled" }) do
	describe(called, function()
		it("works only on spies or jest.fn", function()
			local function fn() end

			expect(function()
				expect(fn)[called]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("passes when called", function()
			local fn = mock:fn()
			fn("arg0", "arg1", "arg2")
			expect(createSpy(fn))[called]()
			expect(fn)[called]()
			expect(function()
				expect(fn).never[called]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes when called", function()
			local fn = mock:fn()
			local spy = createSpy(fn)

			expect(spy).never[called]()
			expect(fn).never[called]()
			expect(function()
				expect(spy)[called]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("fails with any argument passed", function()
			local fn = mock:fn()

			fn()
			expect(function()
				expect(fn)[called](555)
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not fails with any argument passed", function()
			local fn = mock:fn()

			expect(function()
				expect(fn).never[called](555)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("includes the custom mock name in the error message", function()
			local fn = mock:fn().mockName("named-mock")

			fn()
			expect(fn)[called]()
			expect(function()
				expect(fn).never[called]()
			end).toThrowErrorMatchingSnapshot()
		end)
	end)
end

for _, calledTimes in ipairs({ "toBeCalledTimes", "toHaveBeenCalledTimes" }) do
	describe(("%s"):format(calledTimes), function()
		it(".not works only on spies or jest.fn", function()
			local function fn() end

			expect(function()
				expect(fn).never[calledTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("only accepts a number argument", function()
			local fn = mock:fn()
			fn()
			expect(fn)[calledTimes](1)

			for i, value in ipairs({ {}, true, "a", function() end }) do
				expect(function()
					expect(fn)[calledTimes](value)
				end).toThrowErrorMatchingSnapshot()
			end
		end)

		it(".not only accepts a number argument", function()
			local fn = mock:fn()
			expect(fn).never[calledTimes](1)

			for i, value in ipairs({ {}, true, "a", function() end }) do
				expect(function()
					expect(fn).never[calledTimes](value)
				end).toThrowErrorMatchingSnapshot()
			end
		end)

		it("passes if function called equal to expected times", function()
			local fn = mock:fn()
			fn()
			fn()

			local spy = createSpy(fn)
			expect(spy)[calledTimes](2)
			expect(fn)[calledTimes](2)

			expect(function()
				expect(spy).never[calledTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes if function called more than expected times", function()
			local fn = mock:fn()
			fn()
			fn()
			fn()

			local spy = createSpy(fn)
			expect(spy)[calledTimes](3)
			expect(spy).never[calledTimes](2)

			expect(fn)[calledTimes](3)
			expect(fn).never[calledTimes](2)

			expect(function()
				expect(fn)[calledTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes if function called less than expected times", function()
			local fn = mock:fn()
			fn()

			local spy = createSpy(fn)
			expect(spy)[calledTimes](1)
			expect(spy).never[calledTimes](2)

			expect(fn)[calledTimes](1)
			expect(fn).never[calledTimes](2)

			expect(function()
				expect(fn)[calledTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("includes the custom mock name in the error message", function()
			local fn = mock:fn().mockName("named-mock")
			fn()

			expect(function()
				expect(fn)[calledTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)
	end)
end

for _, calledWith in ipairs({
	"lastCalledWith",
	"toHaveBeenLastCalledWith",
	"nthCalledWith",
	"toHaveBeenNthCalledWith",
	"toBeCalledWith",
	"toHaveBeenCalledWith",
}) do
	local caller = function(callee: any, ...)
		if calledWith == "nthCalledWith" or calledWith == "toHaveBeenNthCalledWith" then
			callee(1, ...)
		else
			callee(...)
		end
	end

	describe(("%s"):format(calledWith), function()
		it("works only on spies or jest.fn", function()
			local function fn() end

			expect(function()
				expect(fn)[calledWith]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works when not called", function()
			local fn = mock:fn()
			caller(expect(createSpy(fn)).never[calledWith], "foo", "bar")
			caller(expect(fn).never[calledWith], "foo", "bar")

			expect(function()
				caller(expect(fn)[calledWith], "foo", "bar")
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with no arguments", function()
			local fn = mock:fn()
			fn()

			caller(expect(createSpy(fn))[calledWith])
			caller(expect(fn)[calledWith])
		end)

		it("works with arguments that don't match", function()
			local fn = mock:fn()
			fn("foo", "bar1")

			caller(expect(createSpy(fn)).never[calledWith], "foo", "bar")
			caller(expect(fn).never[calledWith], "foo", "bar")

			expect(function()
				caller(expect(fn)[calledWith], "foo", "bar")
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with arguments that match", function()
			local fn = mock:fn()
			fn("foo", "bar")

			caller(expect(createSpy(fn))[calledWith], "foo", "bar")
			caller(expect(fn)[calledWith], "foo", "bar")

			expect(function()
				caller(expect(fn).never[calledWith], "foo", "bar")
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: changed undefined to nil
		it("works with trailing undefined arguments", function()
			local fn = mock:fn()
			fn("foo", nil)

			expect(function()
				caller(expect(fn)[calledWith], "foo")
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: test changed from Map to table
		it("works with Map", function()
			local fn = mock:fn()

			local m1 = {
				{ 1, 2 },
				{ 2, 1 },
			}
			local m2 = {
				{ 1, 2 },
				{ 2, 1 },
			}
			local m3 = {
				{ "a", "b" },
				{ "b", "a" },
			}

			fn(m1)

			caller(expect(fn)[calledWith], m2)
			caller(expect(fn).never[calledWith], m3)

			expect(function()
				caller(expect(fn).never[calledWith], m2)
			end).toThrowErrorMatchingSnapshot()

			expect(function()
				caller(expect(fn)[calledWith], m3)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with Set", function()
			local fn = mock:fn()

			local s1 = Set.new({ 1, 2 })
			local s2 = Set.new({ 1, 2 })
			local s3 = Set.new({ 3, 4 })

			fn(s1)

			caller(expect(fn)[calledWith], s2)
			caller(expect(fn).never[calledWith], s3)

			expect(function()
				caller(expect(fn).never[calledWith], s2)
			end).toThrowErrorMatchingSnapshot()

			expect(function()
				caller(expect(fn)[calledWith], s3)
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: skipped test that relies on Immutable.js
		it.skip("works with Immutable.js objects", function() end)

		-- ROBLOX deviation: changed from array to table with keys as array
		-- entries and value as true for quick lookup
		local basicCalledWith = {
			lastCalledWith = true,
			toHaveBeenLastCalledWith = true,
			toBeCalledWith = true,
			toHaveBeenCalledWith = true,
		}

		if basicCalledWith[calledWith] then
			it("works with many arguments", function()
				local fn = mock:fn()
				fn("foo1", "bar")
				fn("foo", "bar1")
				fn("foo", "bar")

				expect(fn)[calledWith]("foo", "bar")

				expect(function()
					expect(fn).never[calledWith]("foo", "bar")
				end).toThrowErrorMatchingSnapshot()
			end)

			it("works with many arguments that don't match", function()
				local fn = mock:fn()
				fn("foo", "bar1")
				fn("foo", "bar2")
				fn("foo", "bar3")

				expect(fn).never[calledWith]("foo", "bar")

				expect(function()
					expect(fn)[calledWith]("foo", "bar")
				end).toThrowErrorMatchingSnapshot()
			end)
		end

		-- ROBLOX deviation: changed from array to table with keys as array
		-- entries and value as true for quick lookup
		local nthCalled = {
			toHaveBeenNthCalledWith = true,
			nthCalledWith = true,
		}

		if nthCalled[calledWith] then
			it("works with three calls", function()
				local fn = mock:fn()
				fn("foo1", "bar")
				fn("foo", "bar1")
				fn("foo", "bar")

				expect(fn)[calledWith](1, "foo1", "bar")
				expect(fn)[calledWith](2, "foo", "bar1")
				expect(fn)[calledWith](3, "foo", "bar")

				expect(function()
					expect(fn).never[calledWith](1, "foo1", "bar")
				end).toThrowErrorMatchingSnapshot()
			end)

			it("positive throw matcher error for n that is not positive integer", function()
				local fn = mock:fn()
				fn("foo1", "bar")

				expect(function()
					expect(fn)[calledWith](0, "foo1", "bar")
				end).toThrowErrorMatchingSnapshot()
			end)

			it("positive throw matcher error for n that is not integer", function()
				local fn = mock:fn()
				fn("foo1", "bar")

				expect(function()
					expect(fn)[calledWith](0.1, "foo1", "bar")
				end).toThrowErrorMatchingSnapshot()
			end)

			it("negative throw matcher error for n that is not integer", function()
				local fn = mock:fn()
				fn("foo1", "bar")

				expect(function()
					expect(fn).never[calledWith](math.huge, "foo1", "bar")
				end).toThrowErrorMatchingSnapshot()
			end)
		end

		it("includes the custom mock name in the error message", function()
			local fn = mock:fn().mockName("named-mock")
			fn("foo", "bar")

			caller(expect(fn)[calledWith], "foo", "bar")

			expect(function()
				caller(expect(fn).never[calledWith], "foo", "bar")
			end).toThrowErrorMatchingSnapshot()
		end)
	end)
end

for _, returned in ipairs({ "toReturn", "toHaveReturned" }) do
	describe(("%s"):format(returned), function()
		it(".not works only on jest.fn", function()
			local function fn() end

			expect(function()
				expect(fn).never[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("throw matcher error if received is spy", function()
			local spy = createSpy(mock:fn())

			expect(function()
				expect(spy)[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("passes when returned", function()
			local fn = mock:fn(function()
				return 42
			end)
			fn()
			expect(fn)[returned]()
			expect(function()
				expect(fn).never[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: changed undefined to nil
		it("passes when undefined is returned", function()
			local fn = mock:fn(function()
				return nil
			end)
			fn()
			expect(fn)[returned]()
			expect(function()
				expect(fn).never[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("passes when at least one call does not throw", function()
			local fn = mock:fn(function(causeError)
				if causeError then
					error(Error("Error!"))
				end

				return 42
			end)

			fn(false)

			pcall(function()
				fn(true)
			end)

			fn(false)

			expect(fn)[returned]()

			expect(function()
				expect(fn).never[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes when not returned", function()
			local fn = mock:fn()

			expect(fn).never[returned]()
			expect(function()
				expect(fn)[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes when all calls throw", function()
			local fn = mock:fn(function()
				error(Error("Error!"))
			end)

			pcall(function()
				fn()
			end)

			pcall(function()
				fn()
			end)

			expect(fn).never[returned]()
			expect(function()
				expect(fn)[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: changed undefined to nil
		it(".not passes when a call throws undefined", function()
			local fn = mock:fn(function()
				error(nil)
			end)

			pcall(function()
				fn()
			end)

			expect(fn).never[returned]()
			expect(function()
				expect(fn)[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("fails with any argument passed", function()
			local fn = mock:fn()

			fn()
			expect(function()
				expect(fn)[returned](555)
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not fails with any argument passed", function()
			local fn = mock:fn()

			expect(function()
				expect(fn).never[returned](555)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("includes the custom mock name in the error message", function()
			local fn = mock:fn(function()
				return 42
			end).mockName("named-mock")
			fn()
			expect(fn)[returned]()
			expect(function()
				expect(fn).never[returned]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("incomplete recursive calls are handled properly", function()
			-- sums up all integers from 0 -> value, using recursion
			local fn
			fn = mock:fn(function(value)
				if value == 0 then
					-- Before returning from the base case of recursion, none of the
					-- calls have returned yet.
					expect(fn).never[returned]()
					expect(function()
						expect(fn)[returned]()
					end).toThrowErrorMatchingSnapshot()

					return 0
				else
					return value + fn(value - 1)
				end
			end)

			fn(3)
		end)
	end)
end

for _, returnedTimes in ipairs({ "toReturnTimes", "toHaveReturnedTimes" }) do
	describe(("%s"):format(returnedTimes), function()
		it("throw matcher error if received is spy", function()
			local spy = createSpy(mock:fn())

			-- ROBLOX deviation: we don't test against the snapshot because the error
			-- message is sufficiently deviated (we report a table instead of a function)
			expect(function()
				expect(spy).never[returnedTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("only accepts a number argument", function()
			local fn = mock:fn(function()
				return 42
			end)
			fn()
			expect(fn)[returnedTimes](1)

			for i, value in ipairs({ {}, true, "a", function() end }) do
				expect(function()
					expect(fn)[returnedTimes](value)
				end).toThrowErrorMatchingSnapshot()
			end
		end)

		it(".not only accepts a number argument", function()
			local fn = mock:fn(function()
				return 42
			end)
			expect(fn).never[returnedTimes](2)

			for i, value in ipairs({ {}, true, "a", function() end }) do
				expect(function()
					expect(fn).never[returnedTimes](value)
				end).toThrowErrorMatchingSnapshot()
			end
		end)

		it("passes if function returned equal to expected times", function()
			local fn = mock:fn(function()
				return 42
			end)
			fn()
			fn()

			expect(fn)[returnedTimes](2)

			expect(function()
				expect(fn).never[returnedTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: changed undefined to nil
		it("calls that return undefined are counted as returns", function()
			local fn = mock:fn(function()
				return nil
			end)
			fn()
			fn()

			expect(fn)[returnedTimes](2)

			expect(function()
				expect(fn).never[returnedTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes if function returned more than expected times", function()
			local fn = mock:fn(function()
				return 42
			end)
			fn()
			fn()
			fn()

			expect(fn)[returnedTimes](3)
			expect(fn).never[returnedTimes](2)

			expect(function()
				expect(fn)[returnedTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it(".not passes if function called less than expected times", function()
			local fn = mock:fn(function()
				return 42
			end)
			fn()

			expect(fn)[returnedTimes](1)
			expect(fn).never[returnedTimes](2)

			expect(function()
				expect(fn)[returnedTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("calls that throw are not counted", function()
			local fn = mock:fn(function(causeError)
				if causeError then
					error(Error("Error!"))
				end

				return 42
			end)

			fn(false)

			pcall(function()
				fn(true)
			end)

			fn(false)

			expect(fn).never[returnedTimes](3)

			expect(function()
				expect(fn)[returnedTimes](3)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("calls that throw undefined are not counted", function()
			local fn = mock:fn(function(causeError)
				if causeError then
					error(nil)
				end

				return 42
			end)

			fn(false)

			pcall(function()
				fn(true)
			end)

			fn(false)

			expect(fn)[returnedTimes](2)

			expect(function()
				expect(fn).never[returnedTimes](2)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("includes the custom mock name in the error message", function()
			local fn = mock:fn(function()
				return 42
			end).mockName("named-mock")
			fn()
			fn()

			expect(fn)[returnedTimes](2)

			expect(function()
				expect(fn)[returnedTimes](1)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("incomplete recursive calls are handled properly", function()
			-- sums up all integers from 0 -> value, using recursion
			local fn
			fn = mock:fn(function(value)
				if value == 0 then
					return 0
				else
					local recursiveResult = fn(value - 1)

					if value == 2 then
						-- Only 2 of the recursive calls have returned at this point
						expect(fn)[returnedTimes](2)
						expect(function()
							expect(fn).never[returnedTimes](2)
						end).toThrowErrorMatchingSnapshot()
					end

					return value + recursiveResult
				end
			end)

			fn(3)
		end)
	end)
end

for _, returnedWith in ipairs({
	"lastReturnedWith",
	"toHaveLastReturnedWith",
	"nthReturnedWith",
	"toHaveNthReturnedWith",
	"toReturnWith",
	"toHaveReturnedWith",
}) do
	local caller = function(callee, ...)
		if returnedWith == "nthReturnedWith" or returnedWith == "toHaveNthReturnedWith" then
			callee(1, ...)
		else
			callee(...)
		end
	end

	describe(("%s"):format(returnedWith), function()
		it("works only on spies or jest.fn", function()
			local function fn() end

			expect(function()
				expect(fn)[returnedWith]()
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works when not called", function()
			local fn = mock:fn()
			caller(expect(fn).never[returnedWith], "foo")

			expect(function()
				caller(expect(fn)[returnedWith], "foo")
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with no arguments", function()
			local fn = mock:fn()
			fn()

			caller(expect(fn)[returnedWith])
		end)

		it("works with argument that does not match", function()
			local fn = mock:fn(function()
				return "foo"
			end)
			fn()

			caller(expect(fn).never[returnedWith], "bar")

			expect(function()
				caller(expect(fn)[returnedWith], "bar")
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with argument that does match", function()
			local fn = mock:fn(function()
				return "foo"
			end)
			fn()

			caller(expect(fn)[returnedWith], "foo")

			expect(function()
				caller(expect(fn).never[returnedWith], "foo")
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with undefined", function()
			local fn = mock:fn(function()
				return nil
			end)
			fn()

			caller(expect(fn)[returnedWith], nil)

			expect(function()
				caller(expect(fn).never[returnedWith], nil)
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: test changed from Map to table
		it("works with Map", function()
			local m1 = {
				{ 1, 2 },
				{ 2, 1 },
			}
			local m2 = {
				{ 1, 2 },
				{ 2, 1 },
			}
			local m3 = {
				{ "a", "b" },
				{ "b", "a" },
			}

			local fn = mock:fn(function()
				return m1
			end)
			fn()

			caller(expect(fn)[returnedWith], m2)
			caller(expect(fn).never[returnedWith], m3)

			expect(function()
				caller(expect(fn).never[returnedWith], m2)
			end).toThrowErrorMatchingSnapshot()
			expect(function()
				caller(expect(fn)[returnedWith], m3)
			end).toThrowErrorMatchingSnapshot()
		end)

		it("works with Set", function()
			local s1 = Set.new({ 1, 2 })
			local s2 = Set.new({ 1, 2 })
			local s3 = Set.new({ 3, 4 })

			local fn = mock:fn(function()
				return s1
			end)
			fn()

			caller(expect(fn)[returnedWith], s2)
			caller(expect(fn).never[returnedWith], s3)

			expect(function()
				caller(expect(fn).never[returnedWith], s2)
			end).toThrowErrorMatchingSnapshot()

			expect(function()
				caller(expect(fn)[returnedWith], s3)
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: skipped test that relies on Immutable.js
		it.skip("works with Immutable.js objects directly created", function() end)

		it("a call that throws is not considered to have returned", function()
			local fn = mock:fn(function()
				error(Error("Error!"))
			end)

			pcall(function()
				fn()
			end)

			-- It doesn't matter what return value is tested if the call threw
			caller(expect(fn).never[returnedWith], "foo")
			caller(expect(fn).never[returnedWith], nil)
			-- ROBLOX deviation: omitted call with undefined value

			expect(function()
				caller(expect(fn)[returnedWith], nil)
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: changed undefined to nil
		it("a call that throws undefined is not considered to have returned", function()
			local fn = mock:fn(function()
				error(nil)
			end)

			pcall(function()
				fn()
			end)

			-- It doesn't matter what return value is tested if the call threw
			caller(expect(fn).never[returnedWith], "foo")
			caller(expect(fn).never[returnedWith], nil)
			-- ROBLOX deviation: omitted call with undefined value

			expect(function()
				caller(expect(fn)[returnedWith], nil)
			end).toThrowErrorMatchingSnapshot()
		end)

		-- ROBLOX deviation: changed from array to table with keys as array
		-- entries and value as true for quick lookup
		local basicReturnedWith = {
			toHaveReturnedWith = true,
			toReturnWith = true,
		}

		if basicReturnedWith[returnedWith] then
			describe("returnedWith", function()
				it("works with more calls than the limit", function()
					local fn = mock:fn()
					fn.mockReturnValueOnce("foo1")
					fn.mockReturnValueOnce("foo2")
					fn.mockReturnValueOnce("foo3")
					fn.mockReturnValueOnce("foo4")
					fn.mockReturnValueOnce("foo5")
					fn.mockReturnValueOnce("foo6")

					fn()
					fn()
					fn()
					fn()
					fn()
					fn()

					expect(fn).never[returnedWith]("bar")

					expect(function()
						expect(fn)[returnedWith]("bar")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("incomplete recursive calls are handled properly", function()
					-- sums up all integers from 0 -> value, using recursion
					local fn
					fn = mock:fn(function(value)
						if value == 0 then
							-- Before returning from the base case of recursion, none of the
							-- calls have returned yet.
							-- This test ensures that the incomplete calls are not incorrectly
							-- interpretted as have returned undefined
							expect(fn).never[returnedWith](nil)
							expect(function()
								expect(fn)[returnedWith](nil)
							end).toThrowErrorMatchingSnapshot()

							return 0
						else
							return value + fn(value - 1)
						end
					end)

					fn(3)
				end)
			end)
		end

		-- ROBLOX deviation: changed from array to table with keys as array
		-- entries and value as true for quick lookup
		local nthReturnedWith = {
			toHaveNthReturnedWith = true,
			nthReturnedWith = true,
		}

		if nthReturnedWith[returnedWith] then
			describe("nthReturnedWith", function()
				it("works with three calls", function()
					local fn = mock:fn()
					fn.mockReturnValueOnce("foo1")
					fn.mockReturnValueOnce("foo2")
					fn.mockReturnValueOnce("foo3")
					fn()
					fn()
					fn()

					expect(fn)[returnedWith](1, "foo1")
					expect(fn)[returnedWith](2, "foo2")
					expect(fn)[returnedWith](3, "foo3")

					expect(function()
						expect(fn).never[returnedWith](1, "foo1")
						expect(fn).never[returnedWith](2, "foo2")
						expect(fn).never[returnedWith](3, "foo3")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("should replace 1st, 2nd, 3rd with first, second, third", function()
					local fn = mock:fn()
					fn.mockReturnValueOnce("foo1")
					fn.mockReturnValueOnce("foo2")
					fn.mockReturnValueOnce("foo3")
					fn()
					fn()
					fn()

					expect(function()
						expect(fn)[returnedWith](1, "bar1")
						expect(fn)[returnedWith](2, "bar2")
						expect(fn)[returnedWith](3, "bar3")
					end).toThrowErrorMatchingSnapshot()

					expect(function()
						expect(fn).never[returnedWith](1, "foo1")
						expect(fn).never[returnedWith](2, "foo2")
						expect(fn).never[returnedWith](3, "foo3")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("positive throw matcher error for n that is not positive integer", function()
					local fn = mock:fn(function()
						return "foo"
					end)
					fn()

					expect(function()
						expect(fn)[returnedWith](0, "foo")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("should reject nth value greater than number of calls", function()
					local fn = mock:fn(function()
						return "foo"
					end)
					fn()
					fn()
					fn()

					expect(function()
						expect(fn)[returnedWith](4, "foo")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("positive throw matcher error for n that is not integer", function()
					local fn = mock:fn(function()
						return "foo"
					end)
					fn("foo")

					expect(function()
						expect(fn)[returnedWith](0.1, "foo")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("negative throw matcher error for n that is not number", function()
					local fn = mock:fn(function()
						return "foo"
					end)
					fn("foo")

					expect(function()
						expect(fn).never[returnedWith]()
					end).toThrowErrorMatchingSnapshot()
				end)

				it("incomplete recursive calls are handled properly", function()
					-- sums up all integers from 0 -> value, using recursion
					local fn
					fn = mock:fn(function(value)
						if value == 0 then
							return 0
						else
							local recursiveResult = fn(value - 1)

							if value == 2 then
								-- Only 2 of the recursive calls have returned at this point
								expect(fn).never[returnedWith](1, 6)
								expect(fn).never[returnedWith](2, 3)
								expect(fn)[returnedWith](3, 1)
								expect(fn)[returnedWith](4, 0)

								expect(function()
									expect(fn)[returnedWith](1, 6)
								end).toThrowErrorMatchingSnapshot()
								expect(function()
									expect(fn)[returnedWith](2, 3)
								end).toThrowErrorMatchingSnapshot()
								expect(function()
									expect(fn).never[returnedWith](3, 1)
								end).toThrowErrorMatchingSnapshot()
								expect(function()
									expect(fn).never[returnedWith](4, 0)
								end).toThrowErrorMatchingSnapshot()
							end

							return value + recursiveResult
						end
					end)

					fn(3)
				end)
			end)
		end

		-- ROBLOX deviation: changed from array to table with keys as array
		-- entries and value as true for quick lookup
		local lastReturnedWith = {
			toHaveLastReturnedWith = true,
			lastReturnedWith = true,
		}
		if lastReturnedWith[returnedWith] then
			describe("lastReturnedWith", function()
				it("works with three calls", function()
					local fn = mock:fn()
					fn.mockReturnValueOnce("foo1")
					fn.mockReturnValueOnce("foo2")
					fn.mockReturnValueOnce("foo3")
					fn()
					fn()
					fn()

					expect(fn)[returnedWith]("foo3")

					expect(function()
						expect(fn).never[returnedWith]("foo3")
					end).toThrowErrorMatchingSnapshot()
				end)

				it("incomplete recursive calls are handled properly", function()
					-- sums up all integers from 0 -> value, using recursion
					local fn
					fn = mock:fn(function(value)
						if value == 0 then
							-- Before returning from the base case of recursion, none of the
							-- calls have returned yet
							expect(fn).never[returnedWith](0)
							expect(function()
								expect(fn)[returnedWith](0)
							end).toThrowErrorMatchingSnapshot()
							return 0
						else
							return value + fn(value - 1)
						end
					end)

					fn(3)
				end)
			end)
		end

		it("includes the custom mock name in the error message", function()
			local fn = mock:fn().mockName("named-mock")
			caller(expect(fn).never[returnedWith], "foo")

			expect(function()
				caller(expect(fn)[returnedWith], "foo")
			end).toThrowErrorMatchingSnapshot()
		end)
	end)
end

return {}
