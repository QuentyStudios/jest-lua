-- ROBLOX NOTE: no upstream
local LuauPolyfill = require("@pkg/@jsdotlua/luau-polyfill")
local setTimeout = LuauPolyfill.setTimeout
local setInterval = LuauPolyfill.setInterval

local JestGlobals = require("@pkg/@jsdotlua/jest-globals")
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local describe = JestGlobals.describe
local test = JestGlobals.test
local jest = JestGlobals.jest
local FRAME_TIME = 15

describe("setTimeout", function()
	beforeEach(function()
		jest.useFakeTimers()
	end)

	afterEach(function()
		jest.useRealTimers()
	end)

	test("should not trigger", function()
		local triggered = false
		setTimeout(function()
			triggered = true
		end, 200)
		jest.advanceTimersByTime(199)
		expect(triggered).toBe(false)
	end)

	test("should trigger", function()
		local triggered = false
		setTimeout(function()
			triggered = true
		end, 200)
		jest.advanceTimersByTime(200)
		expect(triggered).toBe(true)
	end)

	test("should trigger with a configurable frame time", function()
		jest.useFakeTimers()
		jest.setEngineFrameTime(FRAME_TIME)
		local triggered = false
		setTimeout(function()
			triggered = true
		end, 10)
		jest.advanceTimersByTime(0)
		expect(triggered).toBe(true)
	end)
end)

describe("setInterval", function()
	beforeEach(function()
		jest.useFakeTimers()
	end)

	afterEach(function()
		jest.useRealTimers()
	end)

	test("should not trigger", function()
		local triggered = 0
		setInterval(function()
			triggered += 1
		end, 200)
		jest.advanceTimersByTime(199)
		expect(triggered).toBe(0)
	end)

	test("should trigger once", function()
		local triggered = 0
		setInterval(function()
			triggered += 1
		end, 200)
		jest.advanceTimersByTime(200)
		expect(triggered).toBe(1)
	end)

	test("should trigger multiple times", function()
		local triggered = 0
		setInterval(function()
			triggered += 1
		end, 200)
		jest.advanceTimersByTime(100)
		expect(triggered).toBe(0)

		jest.advanceTimersByTime(99)
		expect(triggered).toBe(0)

		jest.advanceTimersByTime(1)
		expect(triggered).toBe(1)

		jest.advanceTimersByTime(100)
		expect(triggered).toBe(1)

		jest.advanceTimersByTime(100)
		expect(triggered).toBe(2)

		jest.advanceTimersByTime(199)
		expect(triggered).toBe(2)

		jest.advanceTimersByTime(1)
		expect(triggered).toBe(3)
	end)
end)

describe("task.delay", function()
	beforeEach(function()
		jest.useFakeTimers()
	end)

	afterEach(function()
		jest.useRealTimers()
	end)

	test("should trigger", function()
		local triggered = false
		task.delay(2, function()
			triggered = true
		end)
		jest.advanceTimersByTime(2000)
		expect(triggered).toBe(true)
	end)

	test("should not trigger", function()
		local triggered = false
		task.delay(2, function()
			triggered = true
		end)
		jest.advanceTimersByTime(1999)
		expect(triggered).toBe(false)
	end)

	test("should not timeout", function()
		local triggered = false
		task.delay(10, function()
			triggered = true
		end)
		jest.advanceTimersByTime(10000)
		expect(triggered).toBe(true)
	end, 1000)

	test("should return the thread the callback runs on", function()
		local callbackThread
		local thread = task.delay(1, function()
			callbackThread = coroutine.running()
		end)
		expect(typeof(thread)).toBe("thread")
		jest.advanceTimersByTime(1000)
		expect(callbackThread).toBe(thread)
		expect(callbackThread).never.toBe(coroutine.running())
	end)

	test("should pass arguments to the callback", function()
		local count, a, b, c
		task.delay(1, function(...)
			count = select("#", ...)
			a, b, c = ...
		end, 1, nil, 3)
		jest.advanceTimersByTime(1000)
		expect(count).toBe(3)
		expect(a).toBe(1)
		expect(b).toBe(nil)
		expect(c).toBe(3)
	end)

	test("should accept a thread", function()
		local received
		local thread = coroutine.create(function(value)
			received = value
		end)
		expect(task.delay(1, thread, "value")).toBe(thread)
		jest.advanceTimersByTime(1000)
		expect(received).toBe("value")
	end)

	test("should not suspend the test when the callback yields", function()
		local count = 0
		task.delay(0, function()
			while true do
				count += 1
				task.wait(0.05)
			end
		end)

		jest.advanceTimersByTime(100)
		expect(count).toBe(3)
		jest.advanceTimersByTime(50)
		expect(count).toBe(4)
		jest.runOnlyPendingTimers()
		expect(count).toBe(5)
		jest.advanceTimersToNextTimer()
		expect(count).toBe(6)
	end)

	test("should rethrow errors raised by the callback", function()
		local triggered = false
		task.delay(1, function()
			error("callback error")
		end)
		task.delay(2, function()
			triggered = true
		end)

		expect(function()
			jest.advanceTimersByTime(2000)
		end).toThrow("callback error")
		expect(triggered).toBe(false)

		jest.advanceTimersByTime(2000)
		expect(triggered).toBe(true)
	end)

	test("should include the callback's stack trace in rethrown errors", function()
		task.delay(1, function()
			error("callback error")
		end)

		local success, err = pcall(jest.advanceTimersByTime, 1000)
		expect(success).toBe(false)

		local message, stackTrace = string.match(err, "^(.-)\n(.+)$")
		expect(message).toContain("callback error")
		expect(stackTrace).never.toBeNil()
	end)

	test("should abort a callback that never stops waiting", function()
		task.delay(0, function()
			while true do
				task.wait()
			end
		end)

		expect(function()
			jest.advanceTimersByTime(100)
		end).toThrow("Aborting after running 100000 timers, assuming an infinite loop!")
	end)

	test("should abort runAllTimers when timers keep rescheduling", function()
		local function reschedule()
			task.delay(1, reschedule)
		end
		task.delay(1, reschedule)

		expect(function()
			jest.runAllTimers()
		end).toThrow("Aborting after running 100000 timers, assuming an infinite loop!")
	end)
end)

describe("task.cancel", function()
	beforeEach(function()
		jest.useFakeTimers()
	end)

	afterEach(function()
		jest.useRealTimers()
	end)

	test("timeout should be canceled and not trigger", function()
		local triggered = false
		local timeout = task.delay(2, function()
			triggered = true
		end)
		task.cancel(timeout)
		jest.advanceTimersByTime(2000)
		expect(triggered).toBe(false)
	end)

	test("one timeout should be canceled and not trigger", function()
		local triggered1 = false
		local triggered2 = false
		local timeout1 = task.delay(2, function()
			triggered1 = true
		end)
		local _timeout2 = task.delay(2, function()
			triggered2 = true
		end)

		task.cancel(timeout1)
		jest.advanceTimersByTime(2000)
		expect(triggered1).toBe(false)
		expect(triggered2).toBe(true)
	end)

	test("cancel after delayed task runs", function()
		local triggered = false
		local timeout = task.delay(2, function()
			triggered = true
		end)
		jest.advanceTimersByTime(2000)
		task.cancel(timeout)
		expect(triggered).toBe(true)
	end)

	test("should cancel a thread waiting in task.wait", function()
		local count = 0
		local thread = task.spawn(function()
			while true do
				task.wait(1)
				count += 1
			end
		end)

		jest.advanceTimersByTime(1000)
		expect(count).toBe(1)

		task.cancel(thread)
		expect(coroutine.status(thread)).toBe("dead")
		expect(jest.getTimerCount()).toBe(0)

		jest.advanceTimersByTime(5000)
		expect(count).toBe(1)
	end)

	test("should cancel a delayed thread while it is waiting", function()
		local count = 0
		local thread = task.delay(0, function()
			while true do
				task.wait(1)
				count += 1
			end
		end)

		jest.advanceTimersByTime(1000)
		expect(count).toBe(1)

		task.cancel(thread)
		jest.advanceTimersByTime(5000)
		expect(count).toBe(1)
		expect(jest.getTimerCount()).toBe(0)
	end)

	test("should cancel a timer from another timer due at the same time", function()
		local triggered2 = false
		local triggered3 = false
		local timeout2
		task.delay(1, function()
			task.cancel(timeout2)
		end)
		timeout2 = task.delay(1, function()
			triggered2 = true
		end)
		task.delay(1, function()
			triggered3 = true
		end)

		jest.advanceTimersByTime(1000)
		expect(triggered2).toBe(false)
		expect(triggered3).toBe(true)
	end)

	test("should skip timers cancelled during runOnlyPendingTimers", function()
		local triggered = false
		local timeout2
		task.delay(1, function()
			task.cancel(timeout2)
		end)
		timeout2 = task.delay(2, function()
			triggered = true
		end)

		jest.runOnlyPendingTimers()
		expect(triggered).toBe(false)
	end)
end)

describe("task.wait", function()
	beforeEach(function()
		jest.useFakeTimers()
	end)

	afterEach(function()
		jest.useRealTimers()
	end)

	test("should wait for the specified time", function()
		local elapsed = 0
		coroutine.wrap(function()
			elapsed = task.wait(2)
		end)()
		jest.advanceTimersByTime(2000)
		expect(elapsed).toBe(2)
	end)

	test("should not proceed before the specified time", function()
		local elapsed = 0
		coroutine.wrap(function()
			elapsed = task.wait(2)
		end)()
		jest.advanceTimersByTime(1999)
		expect(elapsed).toBe(0)
	end)

	test("should default to frame time if no time is specified", function()
		local elapsed = 0
		coroutine.wrap(function()
			elapsed = task.wait()
		end)()
		jest.advanceTimersByTime(1000 / 60)
		expect(elapsed).toBeCloseTo(1 / 60, 0.001)
	end)

	test("multiple waits should accumulate correctly", function()
		local elapsed1, elapsed2 = 0, 0
		coroutine.wrap(function()
			elapsed1 = task.wait(1)
			elapsed2 = task.wait(2)
		end)()
		jest.advanceTimersByTime(1000)
		expect(elapsed1).toBe(1)
		expect(elapsed2).toBe(0)
		jest.advanceTimersByTime(2000)
		expect(elapsed1).toBe(1)
		expect(elapsed2).toBe(2)
	end)
end)
