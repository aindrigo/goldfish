--[[
Copyright (c) 2026 aindrigo. 
This library is licensed under the GNU Lesser General Public License version 3.0 or any later version.
See the bottom of the file for a full copy of the GNU Lesser General Public License version 3.0.
]]

-- BEGIN lua-struct (MIT License)
--[[
 * Copyright (c) 2015-2020 Iryont <https://github.com/iryont/lua-struct>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
]]

local unpack = table.unpack or _G.unpack

local struct = {}

function struct.pack(format, ...)
    local stream = {}
    local vars = {...}
    local endianness = true

    for i = 1, format:len() do
        local opt = format:sub(i, i)

        if opt == '<' then
            endianness = true
        elseif opt == '>' then
            endianness = false
        elseif opt:find('[bBhHiIlL]') then
            local n = opt:find('[hH]') and 2 or opt:find('[iI]') and 4 or opt:find('[lL]') and 8 or 1
            local val = tonumber(table.remove(vars, 1))

            local bytes = {}
            for j = 1, n do
                table.insert(bytes, string.char(val % (2 ^ 8)))
                val = math.floor(val / (2 ^ 8))
            end

            if not endianness then
                table.insert(stream, string.reverse(table.concat(bytes)))
            else
                table.insert(stream, table.concat(bytes))
            end
        elseif opt:find('[fd]') then
            local val = tonumber(table.remove(vars, 1))
            local sign = 0

            if val < 0 then
                sign = 1
                val = -val
            end

            local mantissa, exponent = math.frexp(val)
            if val == 0 then
                mantissa = 0
                exponent = 0
            else
                mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, (opt == 'd') and 53 or 24)
                exponent = exponent + ((opt == 'd') and 1022 or 126)
            end

            local bytes = {}
            if opt == 'd' then
                val = mantissa
                for i = 1, 6 do
                    table.insert(bytes, string.char(math.floor(val) % (2 ^ 8)))
                    val = math.floor(val / (2 ^ 8))
                end
            else
                table.insert(bytes, string.char(math.floor(mantissa) % (2 ^ 8)))
                val = math.floor(mantissa / (2 ^ 8))
                table.insert(bytes, string.char(math.floor(val) % (2 ^ 8)))
                val = math.floor(val / (2 ^ 8))
            end

            table.insert(bytes, string.char(math.floor(exponent * ((opt == 'd') and 16 or 128) + val) % (2 ^ 8)))
            val = math.floor((exponent * ((opt == 'd') and 16 or 128) + val) / (2 ^ 8))
            table.insert(bytes, string.char(math.floor(sign * 128 + val) % (2 ^ 8)))
            val = math.floor((sign * 128 + val) / (2 ^ 8))

            if not endianness then
                table.insert(stream, string.reverse(table.concat(bytes)))
            else
                table.insert(stream, table.concat(bytes))
            end
        elseif opt == 's' then
            table.insert(stream, tostring(table.remove(vars, 1)))
            table.insert(stream, string.char(0))
        elseif opt == 'c' then
            local n = format:sub(i + 1):match('%d+')
            local str = tostring(table.remove(vars, 1))
            local len = tonumber(n)
            if len <= 0 then
                len = str:len()
            end
            if len - str:len() > 0 then
                str = str .. string.rep(' ', len - str:len())
            end
            table.insert(stream, str:sub(1, len))
            i = i + n:len()
        end
    end

    return table.concat(stream)
end

function struct.unpack(format, stream, pos)
    local vars = {}
    local iterator = pos or 1
    local endianness = true

    for i = 1, format:len() do
        local opt = format:sub(i, i)

        if opt == '<' then
            endianness = true
        elseif opt == '>' then
            endianness = false
        elseif opt:find('[bBhHiIlL]') then
            local n = opt:find('[hH]') and 2 or opt:find('[iI]') and 4 or opt:find('[lL]') and 8 or 1
            local signed = opt:lower() == opt

            local val = 0
            for j = 1, n do
                local byte = string.byte(stream:sub(iterator, iterator))
                if endianness then
                    val = val + byte * (2 ^ ((j - 1) * 8))
                else
                    val = val + byte * (2 ^ ((n - j) * 8))
                end
                iterator = iterator + 1
            end

            if signed and val >= 2 ^ (n * 8 - 1) then
                val = val - 2 ^ (n * 8)
            end

            table.insert(vars, math.floor(val))
        elseif opt:find('[fd]') then
            local n = (opt == 'd') and 8 or 4
            local x = stream:sub(iterator, iterator + n - 1)
            iterator = iterator + n

            if not endianness then
                x = string.reverse(x)
            end

            local sign = 1
            local mantissa = string.byte(x, (opt == 'd') and 7 or 3) % ((opt == 'd') and 16 or 128)
            for i = n - 2, 1, -1 do
                mantissa = mantissa * (2 ^ 8) + string.byte(x, i)
            end

            if string.byte(x, n) > 127 then
                sign = -1
            end

            local exponent = (string.byte(x, n) % 128) * ((opt == 'd') and 16 or 2) + math.floor(string.byte(x, n - 1) / ((opt == 'd') and 16 or 128))
            if exponent == 0 then
                table.insert(vars, 0.0)
            else
                mantissa = (math.ldexp(mantissa, (opt == 'd') and -52 or -23) + 1) * sign
                table.insert(vars, math.ldexp(mantissa, exponent - ((opt == 'd') and 1023 or 127)))
            end
        elseif opt == 's' then
            local bytes = {}
            for j = iterator, stream:len() do
                if stream:sub(j,j) == string.char(0) or    stream:sub(j) == '' then
                    break
                end

                table.insert(bytes, stream:sub(j, j))
            end

            local str = table.concat(bytes)
            iterator = iterator + str:len() + 1
            table.insert(vars, str)
        elseif opt == 'c' then
            local n = format:sub(i + 1):match('%d+')
            local len = tonumber(n)
            if len <= 0 then
                len = table.remove(vars)
            end

            table.insert(vars, stream:sub(iterator, iterator + len - 1))
            iterator = iterator + len
            i = i + n:len()
        end
    end

    return unpack(vars)
end
-- END lua-struct

--#endregion
local _serial = {}

--#region types
--- @enum serial.Types
_serial.Types = {
    NIL = 0,
    NUMBER = 1,
    STRING = 2,
    BOOLEAN = 3,
    TABLE = 4,
    COLOR = 5,
    VECTOR = 6,
    ANGLES = 7,
    ENTITY = 8
}

_serial.typeNames = {
    ["number"] = _serial.Types.NUMBER,
    ["string"] = _serial.Types.STRING,
    ["table"] = _serial.Types.TABLE,
    ["bool"] = _serial.Types.BOOLEAN,
    ["Color"] = _serial.Types.COLOR,
    ["Vector"] = _serial.Types.VECTOR,
    ["Angle"] = _serial.Types.ANGLES,
    ["Entity"] = _serial.Types.ENTITY,
}

function _serial.GetType(value)
    if value == nil then
        return _serial.Types.NIL
    elseif IsColor(value) then 
        return _serial.Types.COLOR
    end

    return _serial.typeNames[type(value)]
end

--#endregion
--#region serializers
_serial.serializers = {}


function _serial.Serialize(value, typeId)
    local writeType = false
	if not isnumber(typeId) then
        writeType = true
        typeId = _serial.GetType(value)
    end

	local serializer = _serial.serializers[typeId]
	assert(istable(serializer), "cannot serialize type")

	local stream = ""
    if writeType then
        stream = stream .. struct.pack("B", typeId)
    end

	stream = stream .. serializer.write(value)

	return stream
end

function _serial.Deserialize(stream, typeId)
    local length = 0
    if not isnumber(typeId) then
        typeId = struct.unpack("B", stream, 1)
	    assert(isnumber(typeId), "cannot deserialize")

        stream = string.sub(stream, 2, -1)
        length = length + 1
    end

	local serializer = _serial.serializers[typeId]
	assert(istable(serializer), "cannot deserialize type")

    local value, valueSize = serializer.read(stream)
	return value, valueSize + length
end

_serial.serializers[_serial.Types.NIL] = {
    read = function() return nil, 0 end,
    write = function() return "" end
}

local u8max = math.pow(2, 8)
local u16max = math.pow(2, 16)
local u32max = math.pow(2, 32)
local u64max = math.pow(2, 64)
_serial.serializers[_serial.Types.NUMBER] = {
    read = function(stream)
        local numberMeta = struct.unpack("B", stream, 1)
		stream = string.sub(stream, 2, -1)

        local numberType = bit.rshift(numberMeta, 1)
        local unsigned = bit.band(numberMeta, 1) == 1

        if numberType == 0 then
            return struct.unpack("d", stream), 1 + 8
        elseif numberType == 1 then
            return struct.unpack(unsigned and "B" or "b", stream), 1 + 1
        elseif numberType == 2 then
            return struct.unpack(unsigned and "H" or "h", stream), 1 + 2
        elseif numberType == 3 then
            return struct.unpack(unsigned and "I" or "i", stream), 1 + 4
        elseif numberType == 4 then
            return struct.unpack(unsigned and "L" or "l", stream), 1 + 8
        end

        error("unknown number data")
    end,
    write = function(value)
        local numberType = 0
        local unsigned = false
        if math.floor(value) == value then
            unsigned = value >= 0
            local absolute = value
            if not unsigned then
                absolute = -absolute * 2
            end

            if absolute < u8max then
                numberType = 1
            elseif absolute >= u8max and absolute < u16max then
                numberType = 2
            elseif absolute >= u16max and absolute < u32max then
                numberType = 3
            elseif absolute >= u32max and absolute < u64max then
                numberType = 4
            end
        end

        local numberMeta = bit.bor(bit.lshift(numberType, 1), unsigned and 1 or 0)
        local stream = struct.pack("B", numberMeta)

        if numberType == 0 then
            stream = stream .. struct.pack("d", value)
        elseif numberType == 1 then
            stream = stream .. struct.pack(unsigned and "B" or "b", value)
        elseif numberType == 2 then
            stream = stream .. struct.pack(unsigned and "H" or "h", value)
        elseif numberType == 3 then
            stream = stream .. struct.pack(unsigned and "I" or "i", value)
        elseif numberType == 4 then
            stream = stream .. struct.pack(unsigned and "L" or "l", value)
        end

		return stream
    end
}

_serial.serializers[_serial.Types.STRING] = {
    read = function(stream)
		local value = struct.unpack("s", stream, 1)
		return value, string.len(value) + 1
    end,
    write = function(value)
        return struct.pack("s", value)
    end
}

_serial.serializers[_serial.Types.BOOLEAN] = {
    read = function(stream)
		local value = struct.unpack("B", stream, 1)
		return value == 1
    end,
    write = function(value)
        return struct.pack("B", value and 1 or 0)
    end
}

_serial.serializers[_serial.Types.TABLE] = {
    read = function(stream)
        local memberCount, memberCountSize = _serial.Deserialize(stream)
		local totalSize = memberCountSize
		stream = string.sub(stream, 1 + memberCountSize, -1)

        local result = {}
        for _ = 1, memberCount do
            local key, keySize = _serial.Deserialize(stream)
			stream = string.sub(stream, 1 + keySize, -1)

            local value, valueSize = _serial.Deserialize(stream)
			stream = string.sub(stream, 1 + valueSize, -1)

			totalSize = totalSize + keySize + valueSize
            result[key] = value
        end

        return result, totalSize
    end,
    write = function(tbl)
        local memberCount = table.Count(tbl)
        local stream = _serial.Serialize(memberCount)

        for key, value in pairs(tbl) do
            stream = stream .. _serial.Serialize(key) .. _serial.Serialize(value)
        end

		return stream
    end
}

_serial.serializers[_serial.Types.COLOR] = {
    read = function(stream)
        local r, g, b, a = struct.unpack("BBBB", stream, 1)
		stream = string.sub(stream, 5, -1)

        return Color(r, g, b, a), 4
    end,
    write = function(value)
		return struct.pack("BBBB", value.r, value.g, value.b, value.a)
    end
}

local vectorSize = 8 * 3
_serial.serializers[_serial.Types.VECTOR] = {
    read = function(stream)
        local x, y, z = struct.unpack("ddd", stream, 1)
		stream = string.sub(stream, 1 + vectorSize, -1)

        return Vector(x, y, z), vectorSize
    end,
    write = function(value)
		return struct.pack("ddd", value.x, value.y, value.z)
    end
}

_serial.serializers[_serial.Types.ANGLES] = {
    read = function(stream)
        local p, y, r = struct.unpack("ddd", stream, 1)
		stream = string.sub(stream, 1 + vectorSize, -1)

        return Angle(p, y, r), vectorSize
    end,
    write = function(value)
		return struct.pack("ddd", value.p, value.y, value.r)
    end
}

_serial.serializers[_serial.Types.ENTITY] = {
    read = function(stream)
        local index = struct.unpack("H", stream, 1)
        return Entity(index), 2
    end,
    write = function(value)
        return struct.pack("H", value:EntIndex())
    end
}

--#endregion
--#region buffer
local buffer = {}

AccessorFunc(buffer, "_data", "Data", FORCE_STRING)
AccessorFunc(buffer, "_cursor", "Cursor", FORCE_NUMBER)
function buffer:New(source)
    local instance = {}
    setmetatable(instance, {
        __index = buffer,
        __tostring = function(_)
            return string.format("%s: %p", "serial.Buffer", t)
        end,
        MetaName = "serial.Buffer"
    })

	instance:SetCursor(0)
    instance:SetData(source or "")
    return instance
end

function buffer:WriteStruct(value, typeName)
    self._data = self._data .. struct.pack(typeName, value)
end

function buffer:ReadStruct(typeName)
    local value = struct.unpack(typeName, self._data, self._cursor)
    return value
end

function buffer:WriteString(value)
    self:WriteStruct(value, "s")
end

function buffer:WriteBytes(value)
	self._data = self._data .. value
end

function buffer:ReadBytes(length)
	local position = self._cursor
	if length ~= nil then
		position = position + length
	end

	return string.sub(self._data, self._cursor, position)
end

function buffer:ReadString()
    local value = self:ReadStruct("s")
    self._cursor = self._cursor + string.len(value) + 1 -- null-terminated
    return value
end

function buffer:WriteByte(value, unsigned)
    self:WriteStruct(value, unsigned and "B" or "b")
end

function buffer:ReadByte(unsigned)
    local value = self:ReadStruct(unsigned and "B" or "b")
    self._cursor = self._cursor + 1

    return value
end

function buffer:WriteShort(value, unsigned)
    self:WriteStruct(value, unsigned and "H" or "h")
end

function buffer:ReadShort(unsigned)
    local value = self:ReadStruct(unsigned and "H" or "h")
    self._cursor = self._cursor + 2
    return value
end

function buffer:WriteInt(value, unsigned)
    self:WriteStruct(value, unsigned and "I" or "i")
end

function buffer:ReadInt(unsigned)
    local value = self:ReadStruct(unsigned and "I" or "i")
    self._cursor = self._cursor + 4
    return value
end

function buffer:WriteLong(value, unsigned)
    self:WriteStruct(value, unsigned and "L" or "l")
end

function buffer:ReadLong(unsigned)
    local value = self:ReadStruct(unsigned and "L" or "l")
    self._cursor = self._cursor + 8
    return value
end

function buffer:WriteFloat(value)
    self:WriteStruct(value, "f")
end

function buffer:ReadFloat()
    local value = self:ReadStruct("f")
    self._cursor = self._cursor + 4
    return value
end

function buffer:WriteDouble(value)
    self:WriteStruct(value, "d")
end

function buffer:ReadDouble()
    local value = self:ReadStruct("d")
    self._cursor = self._cursor + 8
    return value
end

function buffer:ReadTyped(typeid)
    local serializer = _serial.serializers[typeid]

    assert(istable(serializer), "cannot deserialize type " .. tostring(typeid))
    return serializer.read(self._data)
end

function buffer:WriteTyped(value, typeId)
	if not isnumber(typeId) then
		typeId = _serial.GetType(value)
	end
    local serializer = _serial.serializers[typeId]

    assert(istable(serializer), "cannot serialize type " .. tostring(typeId))
    self._data = self._data .. serializer.write(value)
end

function buffer:ReadAny()
    local value, size = _serial.Deserialize(self._data)
	self._cursor = self._cursor + size

	return value
end

function buffer:WriteAny(value)
    self._data = self._data .. _serial.Serialize(value)
end

setmetatable(buffer, {
    __call = function(self, ...)
        return buffer:New(...)
    end
})

--- @class serial.Buffer
_serial.Buffer = buffer
--#endregion
--#region gamemode implementation
function MODULE:PreEnable()
    _G["serial"] = _serial
end

function MODULE:PreReload()
    _G["serial"] = _serial
end

function MODULE:PostDisable()
    _G["serial"] = nil
end
--#endregion


-- BEGIN GNU LESSER GENERAL PUBLIC LICENSE v3.0
--[[
                   GNU LESSER GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.


  This version of the GNU Lesser General Public License incorporates
the terms and conditions of version 3 of the GNU General Public
License, supplemented by the additional permissions listed below.

  0. Additional Definitions.

  As used herein, "this License" refers to version 3 of the GNU Lesser
General Public License, and the "GNU GPL" refers to version 3 of the GNU
General Public License.

  "The Library" refers to a covered work governed by this License,
other than an Application or a Combined Work as defined below.

  An "Application" is any work that makes use of an interface provided
by the Library, but which is not otherwise based on the Library.
Defining a subclass of a class defined by the Library is deemed a mode
of using an interface provided by the Library.

  A "Combined Work" is a work produced by combining or linking an
Application with the Library.  The particular version of the Library
with which the Combined Work was made is also called the "Linked
Version".

  The "Minimal Corresponding Source" for a Combined Work means the
Corresponding Source for the Combined Work, excluding any source code
for portions of the Combined Work that, considered in isolation, are
based on the Application, and not on the Linked Version.

  The "Corresponding Application Code" for a Combined Work means the
object code and/or source code for the Application, including any data
and utility programs needed for reproducing the Combined Work from the
Application, but excluding the System Libraries of the Combined Work.

  1. Exception to Section 3 of the GNU GPL.

  You may convey a covered work under sections 3 and 4 of this License
without being bound by section 3 of the GNU GPL.

  2. Conveying Modified Versions.

  If you modify a copy of the Library, and, in your modifications, a
facility refers to a function or data to be supplied by an Application
that uses the facility (other than as an argument passed when the
facility is invoked), then you may convey a copy of the modified
version:

   a) under this License, provided that you make a good faith effort to
   ensure that, in the event an Application does not supply the
   function or data, the facility still operates, and performs
   whatever part of its purpose remains meaningful, or

   b) under the GNU GPL, with none of the additional permissions of
   this License applicable to that copy.

  3. Object Code Incorporating Material from Library Header Files.

  The object code form of an Application may incorporate material from
a header file that is part of the Library.  You may convey such object
code under terms of your choice, provided that, if the incorporated
material is not limited to numerical parameters, data structure
layouts and accessors, or small macros, inline functions and templates
(ten or fewer lines in length), you do both of the following:

   a) Give prominent notice with each copy of the object code that the
   Library is used in it and that the Library and its use are
   covered by this License.

   b) Accompany the object code with a copy of the GNU GPL and this license
   document.

  4. Combined Works.

  You may convey a Combined Work under terms of your choice that,
taken together, effectively do not restrict modification of the
portions of the Library contained in the Combined Work and reverse
engineering for debugging such modifications, if you also do each of
the following:

   a) Give prominent notice with each copy of the Combined Work that
   the Library is used in it and that the Library and its use are
   covered by this License.

   b) Accompany the Combined Work with a copy of the GNU GPL and this license
   document.

   c) For a Combined Work that displays copyright notices during
   execution, include the copyright notice for the Library among
   these notices, as well as a reference directing the user to the
   copies of the GNU GPL and this license document.

   d) Do one of the following:

       0) Convey the Minimal Corresponding Source under the terms of this
       License, and the Corresponding Application Code in a form
       suitable for, and under terms that permit, the user to
       recombine or relink the Application with a modified version of
       the Linked Version to produce a modified Combined Work, in the
       manner specified by section 6 of the GNU GPL for conveying
       Corresponding Source.

       1) Use a suitable shared library mechanism for linking with the
       Library.  A suitable mechanism is one that (a) uses at run time
       a copy of the Library already present on the user's computer
       system, and (b) will operate properly with a modified version
       of the Library that is interface-compatible with the Linked
       Version.

   e) Provide Installation Information, but only if you would otherwise
   be required to provide such information under section 6 of the
   GNU GPL, and only to the extent that such information is
   necessary to install and execute a modified version of the
   Combined Work produced by recombining or relinking the
   Application with a modified version of the Linked Version. (If
   you use option 4d0, the Installation Information must accompany
   the Minimal Corresponding Source and Corresponding Application
   Code. If you use option 4d1, you must provide the Installation
   Information in the manner specified by section 6 of the GNU GPL
   for conveying Corresponding Source.)

  5. Combined Libraries.

  You may place library facilities that are a work based on the
Library side by side in a single library together with other library
facilities that are not Applications and are not covered by this
License, and convey such a combined library under terms of your
choice, if you do both of the following:

   a) Accompany the combined library with a copy of the same work based
   on the Library, uncombined with any other library facilities,
   conveyed under the terms of this License.

   b) Give prominent notice with the combined library that part of it
   is a work based on the Library, and explaining where to find the
   accompanying uncombined form of the same work.

  6. Revised Versions of the GNU Lesser General Public License.

  The Free Software Foundation may publish revised and/or new versions
of the GNU Lesser General Public License from time to time. Such new
versions will be similar in spirit to the present version, but may
differ in detail to address new problems or concerns.

  Each version is given a distinguishing version number. If the
Library as you received it specifies that a certain numbered version
of the GNU Lesser General Public License "or any later version"
applies to it, you have the option of following the terms and
conditions either of that published version or of any later version
published by the Free Software Foundation. If the Library as you
received it does not specify a version number of the GNU Lesser
General Public License, you may choose any version of the GNU Lesser
General Public License ever published by the Free Software Foundation.

  If the Library as you received it specifies that a proxy can decide
whether future versions of the GNU Lesser General Public License shall
apply, that proxy's public statement of acceptance of any version is
permanent authorization for you to choose that version for the
Library.
]]--
-- END GNU LESSER GENERAL PUBLIC LICENSE v3.0