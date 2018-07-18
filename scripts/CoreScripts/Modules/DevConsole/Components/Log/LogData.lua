local LogService = game:GetService("LogService")

local Constants = require(script.Parent.Parent.Parent.Constants)
local EnumToMsgTypeName = Constants.EnumToMsgTypeName

local CircularBuffer = require(script.Parent.Parent.Parent.CircularBuffer)
local Signal = require(script.Parent.Parent.Parent.Signal)

-- 500 is max kept in history in C++ as of 7/2/2018
local MAX_LOG_SIZE = tonumber(settings():GetFVariable("NewDevConsoleMaxLogCount"))
local WARNING_TO_FILTER = {"ClassDescriptor failed to learn", "EventDescriptor failed to learn", "Type failed to learn"}

local convertTimeStamp = require(script.Parent.Parent.Parent.Util.convertTimeStamp)

local LogData = {}
LogData.__index = LogData

local function messageEntry(msg, timeAsStr, type)
	return {
		Message = msg,
		Time = timeAsStr,
		Type = type,
	}
end

-- MOST if not all of this code is copied from the
-- Filter "ClassDescriptor failed to learn" errors
local function ignoreWarningMessageOnAdd(message)
	if message.Type ~= Enum.MessageType.MessageWarning.Value then
		return false
	end
	local found = false
	for _, filterString in ipairs(WARNING_TO_FILTER) do
		if string.find(message.Message, filterString) ~= nil then
			found = true
			break
		end
	end
	return found
end

-- if a message if filtered that means we need to put it into the filtered messages
-- this is defined as the messages that we are searching for when the search
-- feature is being used
local function isMessageFiltered(message, filterTypes, filterTerm)
	-- if any types are flagged on, then we need to check against it
	if #filterTerm == 0 and not next(filterTypes) then
		return false
	end

	if next(filterTypes) then
		if not filterTypes[EnumToMsgTypeName[message.Type]] then
			return false
		end
	end

	if #filterTerm > 0 then
		if string.find(message.Message:lower(), filterTerm:lower()) == nil then
			return false
		end
	end

	return true
end

local function validActiveFilters(filterTypes)
	local validFilters = false
	for _, filterActive in pairs(filterTypes) do
		validFilters = validFilters or filterActive
	end
	return validFilters
end

local function filterMessages(buffer, msgIter, filterTypes, filterTerm)
	buffer:reset()

	local validFilters = validActiveFilters(filterTypes)

	if #filterTerm == 0 and not validFilters then
		return
	end

	local counter = 0
	local msg = msgIter:next()
	while msg do
		if isMessageFiltered(msg, filterTypes, filterTerm) then
			counter = counter + 1
			buffer:push_back(msg)
		end
		msg = msgIter:next()
	end

	if counter == 0 then
		if #filterTerm > 0 then
			local errorMsg = messageEntry(string.format ("\"%s\" was not found", filterTerm), "", 0)
			buffer:push_back(errorMsg)
		else
			local errorMsg = messageEntry("No Messages were found", "", 0)
			buffer:push_back(errorMsg)
		end
	end
end

function LogData:checkErrorWarningCounter(msgType)
	if msgType == Enum.MessageType.MessageWarning.Value then
		self._warningCount = self._warningCount + 1
		self._errorWarningSignal:Fire(self._errorCount, self._warningCount)
	elseif msgType == Enum.MessageType.MessageError.Value then
		self._errorCount = self._errorCount + 1
		self._errorWarningSignal:Fire(self._errorCount, self._warningCount)
	end
end

function LogData.new(isClient)
	local self = {}
	setmetatable(self, LogData)

	self._initialized = false
	self._isClient = isClient

	self._logData = CircularBuffer.new(MAX_LOG_SIZE)
	self._logDataSearched = CircularBuffer.new(MAX_LOG_SIZE)
	self._searchTerm = ""
	self._filters = {}
	self._errorCount = isClient and 0
	self._warningCount = isClient and 0
	self._logDataUpdate = Signal.new()
	self._errorWarningSignal = isClient and Signal.new()

	return self
end

function LogData:Signal()
	return self._logDataUpdate
end

function LogData:Signal2()
	return self._logDataUpdate2
end

function LogData:errorWarningSignal()
	return self._errorWarningSignal
end

function LogData:setSearchTerm(targetSearchTerm)
	if self._searchTerm ~= targetSearchTerm then
		self._searchTerm = targetSearchTerm

		if self._searchTerm == "" then
			self._logDataSearched:reset()
			self._logDataUpdate:Fire(self._logData)
		else
			filterMessages(
				self._logDataSearched,
				self._logData:iterator(),
				self._filters,
				self._searchTerm
			)
			self._logDataUpdate:Fire(self._logDataSearched)
		end
	end
end

function LogData:getSearchTerm()
	return self._searchTerm
end

function LogData:setFilters(filters)
	if not validActiveFilters(filters) then
		self._filters = {}
		self._logDataSearched:reset()
		self._logDataUpdate:Fire(self._logData)
		return
	end
	self._filters = filters

	filterMessages(
		self._logDataSearched,
		self._logData:iterator(),
		self._filters,
		self._searchTerm
	)
	self._logDataUpdate:Fire(self._logDataSearched)
end

function LogData:getLogData()
	return self._logData
end

function LogData:getErrorWarningCount()
	return self._errorCount, self._warningCount
end

function LogData:start()
	if self._isClient then
		if not self._initialized then
			self._initialized = true
			local Messages = {}
			if #Messages == 0 then
				local history = LogService:GetLogHistory()
				for _, msg in ipairs(history) do
					local message = messageEntry(
						msg.message or "[DevConsole Error 1]",
						convertTimeStamp(msg.timestamp),
						msg.messageType.Value
					)
					if not ignoreWarningMessageOnAdd(message) then
						self:checkErrorWarningCounter(msg.messageType.Value)
						self._logData:push_back(message)
					end
				end
			end
		end

		self._connection = LogService.MessageOut:connect(function(text, messageType)
			local message = messageEntry(
				text or "[DevConsole Error 2]",
				convertTimeStamp(os.time()),
				messageType.Value
			)

			if not ignoreWarningMessageOnAdd(message) then
				self:checkErrorWarningCounter(messageType.Value)
				self._logData:push_back(message)

				if #self._logDataSearched:getData() > 0 then
					if isMessageFiltered(message, self._filters, self._searchTerm) then
						self._logDataSearched:push_back(message)
						self._logDataUpdate:Fire(self._logDataSearched)
					end
				else
					self._logDataUpdate:Fire(self._logData)
				end
			end
		end)
	else
		self._connection = LogService.ServerMessageOut:connect(function(text, messageType, timestamp)
			local message = messageEntry(
				text or "[DevConsole Error 3]",
				convertTimeStamp(timestamp),
				messageType.Value
			)

			if not ignoreWarningMessageOnAdd(message) then
				self._logData:push_back(message)

				if #self._logDataSearched:getData() > 0 then
					if isMessageFiltered(message, self._Filters, self._SearchTerm) then
						self._logDataSearched:push_back(message)
						self._logDataUpdate:Fire(self._logDataSearched:front())
					end
				else
					self._logDataUpdate:Fire(self._logData:front())
				end
			end
		end)

		LogService:RequestServerOutput()
	end
end

function LogData:stop()
	self._initialized = false

	if self._connection then
		self._connection:Disconnect()
	end
end

return LogData