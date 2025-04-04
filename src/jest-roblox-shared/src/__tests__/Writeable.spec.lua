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
-- ROBLOX note: no upstream

local Writeable = require("../Writeable").Writeable

local JestConfig = require("@pkg/@jsdotlua/jest-config")

local ModuleMocker = require("@pkg/@jsdotlua/jest-mock").ModuleMocker
local JestGlobals = require("@pkg/@jsdotlua/jest-globals")
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it

local moduleMocker = ModuleMocker.new(JestConfig.projectDefaults)
local mockWrite = moduleMocker:fn()

describe("Writeable", function()
	it("takes a write function and returns a writeable object with the write method attached", function()
		local writeFn = function(data: string)
			mockWrite(data)
		end
		local writeable = Writeable.new({ write = writeFn })
		writeable:write("Hello, world!")
		expect(mockWrite).toBeCalledWith("Hello, world!")
	end)
end)
