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
-- ROBLOX NOTE: https://github.com/facebook/jest/blob/v28.0.0/packages/jest-globals/src/__tests__/index.ts

return (function()
	type Function = (...any) -> ...any

	local JestGlobals = require("@pkg/@jsdotlua/jest-globals")
	local expect = JestGlobals.expect
	local test = JestGlobals.test

	-- quentystudios deviation: importing JestGlobals directly doesn't throw,
	-- since our package entry point requires it eagerly
	test("does not throw when directly imported", function()
		expect(function()
			require("../index")
		end).never.toThrow()
	end)

	return {}
end)()
