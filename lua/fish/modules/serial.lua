--[[
Copyright (c) 2026 aindrigo.
This library is licensed under the GNU Lesser General Public License version 3.0 or any later version.
See the bottom of the file for a full copy of the GNU Lesser General Public License version 3.0.
]]

--- GLua MsgPack implementation
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local floor, frexp, ldexp, abs, huge = math.floor, math.frexp, math.ldexp, math.abs, math.huge
local byte, char, sub, len, reverse = string.byte, string.char, string.sub, string.len, string.reverse

local _serial = {}
_serial.isLittleEndian = true

-- see https://msgpack.org
-- or https://github.com/msgpack/msgpack/blob/master/spec.md
local u8_ceiling = 2 ^ 8
local u16_ceiling = 2 ^ 16
local u32_ceiling = 2 ^ 32
local u64_ceiling = 2 ^ 64

local i8_ceiling = 2 ^ 7
local i16_ceiling = 2 ^ 15
local i32_ceiling = 2 ^ 31
local i64_ceiling = 2 ^ 63

local f32_ceiling = 3.4028235 * (10 ^ 38)
local nan = 0 / 0

--- @enum serial.Format
_serial.Format = {
    NIL = 0xC0,
    BOOLEAN_FALSE = 0xC2,
    BOOLEAN_TRUE = 0xC3,

    FIXINT_POSITIVE = 0x00,
    FIXINT_NEGATIVE = 0xE0,

    UINT_8 = 0xCC,
    UINT_16 = 0xCD,
    UINT_32 = 0xCE,
    UINT_64 = 0xCF,

    INT_8 = 0xD0,
    INT_16 = 0xD1,
    INT_32 = 0xD2,
    INT_64 = 0xD3,

    FLOAT_32 = 0xCA,
    FLOAT_64 = 0xCB,

    FIXSTRING = 0xA0,
    STRING_8 = 0xD9,
    STRING_16 = 0xDA,
    STRING_32 = 0xDB,

    BINARY_8 = 0xC4,
    BINARY_16 = 0xC5,
    BINARY_32 = 0xC6,

    FIXARRAY = 0x90,
    ARRAY_16 = 0xDC,
    ARRAY_32 = 0xDD,

    FIXMAP = 0x80,
    MAP_16 = 0xDE,
    MAP_32 = 0xDF,

    FIXEXT_1 = 0xD4,
    FIXEXT_2 = 0xD5,
    FIXEXT_4 = 0xD6,
    FIXEXT_8 = 0xD7,
    FIXEXT_16 = 0xD8,

    EXT_8 = 0xC7,
    EXT_16 = 0xC8,
    EXT_32 = 0xC9
}

--- @enum serial.Type
_serial.Type = {
    INTEGER = 0,
    NIL = 1,
    BOOLEAN = 2,
    FLOAT = 3,
    STRING = 4,
    BINARY = 5,
    ARRAY = 6,
    MAP = 7,
    EXTENSION = 8
}

--- @enum serial.Option
_serial.Option = {
    None = 0,
    --- Not technically msgpack-compliant but is cheaper on most systems. Use for non-persistent, performance-critical situations.
    LittleEndian = 1,
    --- Forces serialized floats to be double-precision/64-bit
    ForceDoublePrecision = 2
}

--- @enum serial.Profile
_serial.Profile = {
    PERFORMANCE  = bor(_serial.Option.LittleEndian),
    PERSISTENCE = _serial.Option.None
}

-- Packers
_serial.packers = {}
_serial.unpackers = {}

function _serial.packers.Integer(signed, value, byteCount, swapEndianness)
    if signed then
        value = value + 2 ^ (byteCount * 8 - 1)
    end

    local stream = ""

    local loopStart, loopEnd, loopIncr = 1, byteCount, 1

    if swapEndianness then
        loopStart, loopEnd = loopEnd, loopStart
        loopIncr = -1
    end

    for _ = loopStart, loopEnd, loopIncr do
        stream = stream .. char(value % 0x100)
        value = floor(value / 0x100)
    end

    return stream
end

function _serial.unpackers.Integer(signed, stream, cursor, byteCount, swapEndianness)
    local value = 0
    for i = 1, byteCount do
        local pos
        if swapEndianness then
            pos = byteCount - i
        else
            pos = i - 1
        end

        local b = byte(stream, cursor + pos)
        value = value + (b * 2 ^ (pos * 8))
    end

    if signed then
        local mask = 2 ^ (byteCount * 8 - 1)
        if band(value, mask) then
            value = value - mask
        end
    end

    return value
end

function _serial.packers.Float(value, swapEndianness)
    local sign = value < 0 and 0x80 or 0
    value = abs(value)

    local m, e = frexp(value)
    local stream = ""

    if m ~= m then
        stream = stream .. char(0xFF, 0xF8, 0x00, 0x00)
    elseif m == huge or e >= 128 then
        stream = stream .. char(sign == 0 and 0x7F or 0xFF, 0x80, 0x00, 0x00)
    elseif (m == 0 and e == 0) or e < -0x7E then
        stream = stream .. char(sign, 0x00, 0x00, 0x00)
    else
        e = e + 0x7E
        m = floor((m * 2.0 - 1.0) * ldexp(0.5, 24))
        stream = stream ..
            char(sign + floor(e * 0.5), (e % 2) * 0x80 + floor(m / 0x10000),
                floor(m / 256) % 256, m % 256)
    end

    if swapEndianness then
        stream = reverse(stream)
    end
    return stream
end

function _serial.unpackers.Float(stream, cursor, swapEndianness)
    local value = 0
    local b1, b2, b3, b4 = byte(stream, cursor, cursor + 4)
    if swapEndianness then
        b1, b2, b3, b4 = b4, b3, b2, b1
    end

    local sign = b1 > 0x7F and -1 or 1

    local m = ((b2 % 0x80) * 0x100 + b3) * 0x100 + b4
    local e = (b1 % 0x80) * 0x2 + floor(b2 / 0x80)

    if m == 0 and e == 0 then
        value = sign * 0
    elseif expo == 0xFF then
        if m == 0 then
            value = huge * sign
        else
            value = nan
        end
    else
        value = sign * ldexp(1.0 + m / 0x800000, e - 0x7F)
    end

    return value
end

function _serial.packers.Double(value, swapEndianness)
    local sign = value < 0 and 0x80 or 0
    value = abs(value)

    local m, e = frexp(value)
    local stream

    if m ~= m then
        stream = char(0xFF, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    elseif m == huge or e >= 0x400 then
        stream = char(sign == 0 and 0x7F or 0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    elseif (m == 0 and e == 0) or e < -0x3FE then
        stream = char(sign, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    else
        e = e + 0x3FE
        m = floor((m * 2.0 - 1.0) * ldexp(0.5, 53))
        stream = char(sign + floor(e / 0x10),
            (e % 0x10) * 0x10 + floor(m / 0x1000000000000),
            floor(m / 0x10000000000) % 0x100,
            floor(m / 0x100000000) % 0x100,
            floor(m / 0x1000000) % 0x100,
            floor(m / 0x10000) % 0x100,
            floor(m / 0x100) % 0x100,
            m % 0x100
        )
    end

    if swapEndianness then
        stream = reverse(stream)
    end

    return stream
end

function _serial.unpackers.Double(stream, cursor, swapEndianness)
    local value = 0

    local b1, b2, b3, b4, b5, b6, b7, b8 = byte(stream, cursor, cursor + 8)
    if swapEndianness then
        b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
    end

    local sign = b1 > 0x7F and -1 or 1

    local e = (b1 % 0x80) * 0x10 + floor(b2 / 0x10)
    local m = ((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8

    if m == 0 and e == 0 then
        value = sign * 0
    elseif e == 0x7FF then
        if m == 0 then
            value = huge * sign
        else
            value = nan
        end
    else
        value = sign * ldexp(1.0 + m / 4503599627370496, e - 0x3FF)
    end

    return value
end

-- Encoders/decoders
_serial.encoders = {}
_serial.decoders = {}

local intByteCounts = {
    [_serial.Format.UINT_8] = 1,
    [_serial.Format.INT_8] = 1,

    [_serial.Format.UINT_16] = 2,
    [_serial.Format.INT_16] = 2,

    [_serial.Format.UINT_32] = 4,
    [_serial.Format.INT_32] = 4,

    [_serial.Format.UINT_64] = 8,
    [_serial.Format.INT_64] = 8,
}

local intSigned = {
    [_serial.Format.UINT_8] = false,
    [_serial.Format.INT_8] = true,

    [_serial.Format.UINT_16] = false,
    [_serial.Format.INT_16] = true,

    [_serial.Format.UINT_32] = false,
    [_serial.Format.INT_32] = true,

    [_serial.Format.UINT_64] = false,
    [_serial.Format.INT_64] = true,
}

_serial.encoders[_serial.Type.INTEGER] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian
    local format

    if value < 0 then
        local abs = -value

        if abs < 32 then --5bit
            format = _serial.Format.FIXINT_NEGATIVE
        elseif abs < i8_ceiling then
            format = _serial.Format.INT_8
        elseif abs < i16_ceiling then
            format = _serial.Format.INT_16
        elseif abs < i32_ceiling then
            format = _serial.Format.INT_32
        elseif abs < i64_ceiling then
            format = _serial.Format.INT_64
        else
            error("number too small")
        end
    else
        if value < 128 then -- 7bit
            format = _serial.Format.FIXINT_POSITIVE
        elseif value < u8_ceiling then
            format = _serial.Format.UINT_8
        elseif value < u16_ceiling then
            format = _serial.Format.UINT_16
        elseif value < u32_ceiling then
            format = _serial.Format.UINT_32
        elseif value < u64_ceiling then
            format = _serial.Format.UINT_64
        else
            error("number too large")
        end
    end

    if format == _serial.Format.FIXINT_POSITIVE or format == _serial.Format.FIXINT_NEGATIVE then
        return char(bor(abs(value), format))
    end

    local byteCount = intByteCounts[format]
    if not isnumber(byteCount) then
        error("unknown format " .. tostring(format))
    end

    return char(format) .. _serial.packers.Integer(intSigned[format], value, byteCount, swapEndianness)
end

_serial.decoders[_serial.Type.INTEGER] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    if format >= 0x00 and format <= 0x7F then     -- positive fixint limits
        return band(format, 0x7F), 1
    elseif format >= 0xE0 and format <= 0xFF then -- negative fixint limits
        return -band(format, 0x1F), 1
    end

    local byteCount = intByteCounts[format]
    if not isnumber(byteCount) then
        error("unknown format " .. tostring(format))
    end

    local value = _serial.unpackers.Integer(intSigned[format], stream, cursor + 1, byteCount, swapEndianness)
    return value, 1 + byteCount
end

_serial.encoders[_serial.Type.NIL] = function(value)
    return char(_serial.Format.NIL)
end

_serial.decoders[_serial.Type.NIL] = function()
    return nil, 1
end

_serial.encoders[_serial.Type.BOOLEAN] = function(value)
    return char(value and _serial.Format.BOOLEAN_TRUE or _serial.Format.BOOLEAN_FALSE)
end

_serial.decoders[_serial.Type.BOOLEAN] = function(stream, format, cursor, options)
    return format == _serial.Format.BOOLEAN_TRUE, 1
end

_serial.encoders[_serial.Type.FLOAT] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    if value < f32_ceiling and value < u64_ceiling and band(options, _serial.Option.ForceDoublePrecision) ~= _serial.Option.ForceDoublePrecision then
        return char(_serial.Format.FLOAT_32) .. _serial.packers.Float(value, swapEndianness)
    end

    return char(_serial.Format.FLOAT_64) .. _serial.packers.Double(value, swapEndianness)
end

_serial.decoders[_serial.Type.FLOAT] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    if format == _serial.Format.FLOAT_64 then
        return _serial.unpackers.Double(stream, cursor + 1, swapEndianness), 9
    end

    return _serial.unpackers.Float(stream, cursor + 1, swapEndianness), 5
end

_serial.encoders[_serial.Type.STRING] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local length = len(value)
    if length < 32 then -- 5bit
        return char(bor(_serial.Format.FIXSTRING, length)) .. value
    elseif length < u8_ceiling then
        return char(bor(_serial.Format.STRING_8)) ..
            _serial.packers.Integer(false, length, 1, swapEndianness) .. value
    elseif length < u16_ceiling then
        return char(bor(_serial.Format.STRING_16)) ..
            _serial.packers.Integer(false, length, 2, swapEndianness) .. value
    elseif length < u32_ceiling then
        return char(bor(_serial.Format.STRING_32)) ..
            _serial.packers.Integer(false, length, 4, swapEndianness) .. value
    else
        error("string too large")
    end
end

_serial.decoders[_serial.Type.STRING] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local byteCount = 0
    local len = 0

    cursor = cursor + 1
    if (format >= 0xA0 and format <= 0xBF) then
        len = band(0x1F, format)
    else
        if format == _serial.Format.STRING_8 then
            byteCount = 1
        elseif format == _serial.Format.STRING_16 then
            byteCount = 2
        elseif format == _serial.Format.STRING_32 then
            byteCount = 4
        else
            error("unrecognized string format " .. tostring(format))
        end

        len = _serial.unpackers.Integer(false, stream, cursor, byteCount, swapEndianness)

        cursor = cursor + byteCount
    end

    local value = sub(stream, cursor, cursor + len - 1)
    return value, 1 + byteCount + len
end

_serial.encoders[_serial.Type.BINARY] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local length = len(value)
    if length < u8_ceiling then
        return char(bor(_serial.Format.BINARY_8)) .. _serial.packers.Integer(false, length, 1, swapEndianness)
    elseif length < u16_ceiling then
        return char(bor(_serial.Format.BINARY_16)) .. _serial.packers.Integer(false, length, 2, swapEndianness)
    elseif length < u32_ceiling then
        return char(bor(_serial.Format.BINARY_32)) .. _serial.packers.Integer(false, length, 4, swapEndianness)
    else
        error("binary data too large")
    end
end

_serial.decoders[_serial.Type.BINARY] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    cursor = cursor + 1
    local byteCount = 0

    if format == _serial.Format.BINARY_16 then
        byteCount = 2
    elseif format == _serial.Format.BINARY_32 then
        byteCount = 4
    else
        error("unknown format " .. tostring(format))
    end

    cursor = cursor + byteCount
    local length = _serial.unpackers.Integer(stream, cursor, byteCount, swapEndianness)

    local value = sub(stream, cursor, cursor + length)
    return value, 1 + byteCount + length
end

_serial.encoders[_serial.Type.ARRAY] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local serialized = ""
    local length = 0
    for _, v in ipairs(value) do
        serialized = serialized .. _serial.SerializeSingle(v, options)
        length = length + 1
    end

    if length < 16 then -- 4bit
        return char(bor(_serial.Format.FIXARRAY, length)) .. serialized
    elseif length < u16_ceiling then
        return char(bor(_serial.Format.ARRAY_16)) ..
            _serial.packers.Integer(false, length, 2, swapEndianness) .. serialized
    elseif length < u32_ceiling then
        return char(bor(_serial.Format.ARRAY_32)) ..
            _serial.packers.Integer(false, length, 4, swapEndianness) .. serialized
    else
        error("array too large")
    end
end

_serial.decoders[_serial.Type.ARRAY] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local length = 0

    local byteCount = 0
    cursor = cursor + 1

    if (format >= 0x90 and format <= 0x9F) then
        length = band(0xF, format)
    else
        if format == _serial.Format.ARRAY_16 then
            byteCount = 2
        elseif format == _serial.Format.ARRAY_32 then
            byteCount = 4
        else
            error("unknown format " .. format)
        end

        length = _serial.unpackers.Integer(false, stream, cursor, byteCount, swapEndianness)
        cursor = cursor + byteCount
    end

    local arraySize = 0
    local array = {}
    for _ = 1, length do
        local value, valueSize = _serial.DeserializeSingle(stream, options, cursor)
        cursor = cursor + valueSize
        arraySize = arraySize + valueSize

        array[#array + 1] = value
    end

    return array, 1 + byteCount + arraySize
end


_serial.encoders[_serial.Type.MAP] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local serialized = ""
    local length = 0
    for k, v in pairs(value) do
        serialized = serialized .. _serial.SerializeSingle(k, options) .. _serial.SerializeSingle(v, options)
        length = length + 1
    end

    if length < 16 then -- 4bit
        return char(bor(_serial.Format.FIXMAP, length)) .. serialized
    elseif length < u16_ceiling then
        return char(bor(_serial.Format.MAP_16)) ..
            _serial.packers.Integer(false, length, 2, swapEndianness) .. serialized
    elseif length < u32_ceiling then
        return char(bor(_serial.Format.MAP_32)) ..
            _serial.packers.Integer(false, length, 4, swapEndianness) .. serialized
    else
        error("map too large")
    end
end

_serial.decoders[_serial.Type.MAP] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local length = 0

    local byteCount = 0
    cursor = cursor + 1
    if (format >= 0x80 and format <= 0x8F) then
        length = band(0xF, format)
    else
        if format == _serial.Format.MAP_16 then
            byteCount = 2
        elseif format == _serial.Format.MAP_32 then
            byteCount = 4
        else
            error("unknown format " .. format)
        end

        length = _serial.unpackers.Integer(false, stream, cursor, byteCount, swapEndianness)
        cursor = cursor + byteCount
    end

    local mapSize = 0
    local map = {}
    for _ = 1, length do
        local key, keySize = _serial.DeserializeSingle(stream, options, cursor)
        cursor = cursor + keySize

        local value, valueSize = _serial.DeserializeSingle(stream, options, cursor)
        cursor = cursor + valueSize
        mapSize = mapSize + keySize + valueSize

        map[key] = value
    end

    return map, 1 + byteCount + mapSize
end

_serial.encoders[_serial.Type.EXTENSION] = function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian

    local ext, extType
    for i, v in pairs(_serial.extensionTypes) do
        if v.check(value) then
            ext = v
            extType = i
        end
    end

    assert(istable(ext), "no suitable extension type found for value " .. tostring(value))
    value = ext.encode(value, options)

    local length = len(value)
    if length <= 16 then
        if length <= 1 then
            return char(_serial.Format.FIXEXT_1) .. _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
        elseif length <= 2 then
            return char(_serial.Format.FIXEXT_2) .. _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
        elseif length <= 4 then
            return char(_serial.Format.FIXEXT_4) .. _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
        elseif length <= 8 then
            return char(_serial.Format.FIXEXT_8) .. _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
        elseif length <= 16 then
            return char(_serial.Format.FIXEXT_16) .. _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
        end
    elseif length < u8_ceiling then
        return char(_serial.Format.EXT_8) ..
            _serial.packers.Integer(false, length, 1, swapEndianness) ..
            _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
    elseif length < u16_ceiling then
        return char(_serial.Format.EXT_16) ..
            _serial.packers.Integer(false, length, 2, swapEndianness) ..
            _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
    elseif length < u32_ceiling then
        return char(_serial.Format.EXT_32) ..
            _serial.packers.Integer(false, length, 4, swapEndianness) ..
            _serial.packers.Integer(true, extType, 1, swapEndianness) .. value
    else
        error("extension data too large")
    end
end

_serial.decoders[_serial.Type.EXTENSION] = function(stream, format, cursor, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian
    if format >= _serial.Format.FIXEXT_1 and format <= _serial.Format.FIXEXT_16 then
        local type = _serial.unpackers.Integer(true, stream, cursor + 1, 1, swapEndianness)
        local ext = _serial.extensionTypes[type]
        assert(istable(ext), "no such extension type " .. type)

        if format == _serial.Format.FIXEXT_1 then
            return ext.decode(stream, cursor + 2, format, options), 3
        elseif format == _serial.Format.FIXEXT_2 then
            return ext.decode(stream, cursor + 2, format, options), 4
        elseif format == _serial.Format.FIXEXT_4 then
            return ext.decode(stream, cursor + 2, format, options), 6
        elseif format == _serial.Format.FIXEXT_8 then
            return ext.decode(stream, cursor + 2, format, options), 10
        elseif format == _serial.Format.FIXEXT_16 then
            return ext.decode(stream, cursor + 2, format, options), 18
        end
    end

    local type, byteCount
    if format == _serial.Format.EXT_8 then
        type = _serial.unpackers.Integer(true, stream, cursor + 2, 1, swapEndianness)
        byteCount = 1
    elseif format == _serial.Format.EXT_16 then
        type = _serial.unpackers.Integer(true, stream, cursor + 3, 1, swapEndianness)
        byteCount = 2
    elseif format == _serial.Format.EXT_32 then
        type = _serial.unpackers.Integer(true, stream, cursor + 5, 1, swapEndianness)
        byteCount = 4
    end

    local ext = _serial.extensionTypes[type]
    assert(istable(ext), "no such extension type " .. type)

    return ext.decode(stream, cursor + byteCount + 2, format, options), 2 + byteCount
end

-- Extensions

--- Timestamp is a predefined extension type in the msgpack specification
--- @class serial.Timestamp
--- @field seconds number
--- @field nanoseconds number

--- @param seconds? number
--- @param nanoseconds? number
--- @return serial.Timestamp
function _serial.MakeTimestamp(seconds, nanoseconds)
    return { seconds = seconds or 0, nanoseconds = nanoseconds or 0, __serial_timestamp = true }
end

local timestamp_u30_ceiling = 2 ^ 30
local timestamp_u34_ceiling = 2 ^ 34

_serial.extensionTypes = {}
_serial.extensionTypes[-1] = {
    encode = function(value, options)
        local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
            not _serial.isLittleEndian

        if value.nanoseconds == 0 then
            return _serial.packers.Integer(false, value.seconds, 4, swapEndianness)
        elseif value.nanoseconds < timestamp_u30_ceiling and value.seconds < timestamp_u34_ceiling then
            local c1 = value.nanoseconds
            local c2 = value.seconds

            return _serial.packers.Integer(false, lshift(c1, 2), 4, swapEndianness) ..
                _serial.packers.Integer(false, c2, 4, swapEndianness)
        elseif value.nanoseconds < u32_ceiling and value.seconds < u64_ceiling then
            return _serial.packers.Integer(false, value.nanoseconds, 4, swapEndianness) ..
                _serial.packers.Integer(false, value.seconds, 8, swapEndianness)
        else
            error("timestamp too large")
        end
    end,
    decode = function(stream, cursor, format, options)
        local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
            not _serial.isLittleEndian

        if format == _serial.Format.FIXEXT_4 then
            return _serial.MakeTimestamp(_serial.unpackers.Integer(false, stream, cursor, 4, swapEndianness))
        elseif format == _serial.Format.FIXEXT_8 then
            return _serial.MakeTimestamp(_serial.unpackers.Integer(false, stream, cursor + 4, 4, swapEndianness),
                rshift(_serial.unpackers.Integer(false, stream, cursor, 4, swapEndianness), 2))
        elseif format == _serial.Format.EXT_8 then
            return _serial.MakeTimestamp(_serial.unpackers.Integer(false, stream, cursor + 4, 8, swapEndianness),
                _serial.unpackers.Integer(false, stream, cursor, 4, swapEndianness))
        else
            error("invalid timestamp format")
        end
    end,
    check = function(value) return istable(value) and value.__serial_timestamp end
}


-- Utility functions


--- determines type of value
--- @param value any
--- @return serial.Type|string result message if error
function _serial.DetermineType(value)
    for _, ext in pairs(_serial.extensionTypes) do
        if ext.check(value) then
            return _serial.Type.EXTENSION
        end
    end

    if isnumber(value) then
        if floor(value) ~= value or abs(value * 2) >= u64_ceiling or value == nan or value == huge then
            return _serial.Type.FLOAT
        end

        return _serial.Type.INTEGER
    elseif value == nil then
        return _serial.Type.NIL
    elseif isbool(value) then
        return _serial.Type.BOOLEAN
    elseif isstring(value) then
        return _serial.Type.STRING
    elseif istable(value) then
        if table.IsSequential(value) then
            return _serial.Type.ARRAY
        end

        return _serial.Type.MAP
    end

    return "cannot determine type of value " .. tostring(value)
end

local integerFormats = {
    [_serial.Format.UINT_8] = true,
    [_serial.Format.UINT_16] = true,
    [_serial.Format.UINT_32] = true,
    [_serial.Format.UINT_64] = true,
    [_serial.Format.INT_8] = true,
    [_serial.Format.INT_16] = true,
    [_serial.Format.INT_32] = true,
    [_serial.Format.INT_64] = true,
}

--- @param format number
--- @return serial.Type? type
function _serial.FormatToType(format)
    if (format >= 0x00 and format <= 0x7F) or (format >= 0xE0 and format <= 0xFF)
        or integerFormats[format] then
        return _serial.Type.INTEGER
    elseif format == _serial.Format.NIL then
        return _serial.Type.NIL
    elseif format == _serial.Format.BOOLEAN_FALSE or format == _serial.Format.BOOLEAN_TRUE then
        return _serial.Type.BOOLEAN
    elseif format == _serial.Format.FLOAT_32 or format == _serial.Format.FLOAT_64 then
        return _serial.Type.FLOAT
    elseif (format >= 0xA0 and format <= 0xBF) or format == _serial.Format.STRING_8
        or format == _serial.Format.STRING_16 or format == _serial.Format.STRING_32 then
        return _serial.Type.STRING
    elseif format == _serial.Format.BINARY_8 or format == _serial.Format.BINARY_16 or
        format == _serial.Format.BINARY_32 then
        return _serial.Type.BINARY
    elseif (format >= 0x90 and format <= 0x9F) or format == _serial.Format.ARRAY_16
        or format == _serial.Format.ARRAY_32 then
        return _serial.Type.ARRAY
    elseif (format >= 0x80 and format <= 0x8F) or format == _serial.Format.MAP_16
        or format == _serial.Format.MAP_32 then
        return _serial.Type.MAP
    elseif (format >= 0xC7 and format <= 0xC9) or (format >= 0xD4 and format <= 0xD8) then
        return _serial.Type.EXTENSION
    end
end

--- @param stream string
--- @return number stream format
function _serial.GetFormat(stream)
    return byte(stream, 1)
end

--- @param stream string
--- @return serial.Type? stream type
function _serial.GetType(stream)
    return _serial.FormatToType(_serial.GetFormat(stream))
end

--- defines an extension type
--- @param index number 0-127
--- @param encoder fun(value: any, options: number): string
--- @param decoder fun(stream: string, cursor: number, format: serial.Format, options: number): any
--- @param checker fun(value: any): boolean
function _serial.DefineExtensionType(index, encoder, decoder, checker)
    _serial.extensionTypes[index] = { encode = encoder, decode = decoder, check = checker }
end

--- undefines an extension type
--- @param index number 0-127
function _serial.UndefineExtensionType(index)
    _serial.extensionTypes[index] = nil
end

--- @param value any
--- @param options? number serial.SerializerOptions bitflags. must be same on serializer/deserializer
--- @param type? serial.Type
--- @return string data
function _serial.SerializeSingle(value, options, type)
    if type == nil then
        type = _serial.DetermineType(value)
    end

    if options == nil then
        options = _serial.Option.None
    end

    local encoder = _serial.encoders[type]
    return encoder(value, options)
end

--- @param stream string
--- @param options? number serial.SerializerOptions bitflags, must be same on serializer/deserializer
--- @param cursor? number
--- @return any data
--- @return number size size in stream
function _serial.DeserializeSingle(stream, options, cursor)
    cursor = cursor or 1
    if options == nil then
        options = _serial.Option.None
    end

    local format = byte(stream, cursor)
    local type = _serial.FormatToType(format)
    if not type then
        error("invalid format " .. tostring(type) .. " (cannot convert to type)")
    end


    local decoder = _serial.decoders[type]
    return decoder(stream, format, cursor, options or _serial.Option.None)
end

--- @param ... any
--- @return string data
function _serial.Serialize(...)
    return _serial.SerializeSingle({ ... }, nil, _serial.Type.ARRAY)
end

--- @param stream string
--- @param options? number
--- @param cursor? number
--- @return any ...
--- @return number size size in stream
function _serial.Deserialize(stream, options, cursor)
    local value, size = _serial.DeserializeSingle(stream, options, cursor)
    value[#value + 1] = size
    return unpack(value)
end

-- GMod extensions

--- Vector
_serial.DefineExtensionType(0, function(value, options)
    return _serial.SerializeSingle(value.x, options) ..
        _serial.SerializeSingle(value.y, options) .. _serial.SerializeSingle(value.z, options)
end, function(stream, cursor, format, options)
    local x, xSize = _serial.DeserializeSingle(stream, options, cursor)
    cursor = cursor + xSize
    local y, ySize = _serial.DeserializeSingle(stream, options, cursor)
    cursor = cursor + ySize
    local z = _serial.DeserializeSingle(stream, options, cursor)

    return Vector(x, y, z)
end, function(value)
    return isvector(value)
end)

--- Angle
_serial.DefineExtensionType(1, function(value, options)
    return _serial.SerializeSingle(value.p, options) ..
        _serial.SerializeSingle(value.y, options) .. _serial.SerializeSingle(value.r, options)
end, function(stream, cursor, format, options)
    local p, pSize = _serial.DeserializeSingle(stream, options, cursor)
    cursor = cursor + pSize
    local y, ySize = _serial.DeserializeSingle(stream, options, cursor)
    cursor = cursor + ySize
    local r = _serial.DeserializeSingle(stream, options, cursor)

    return Angle(p, y, r)
end, function(value)
    return isangle(value)
end)

--- Color
_serial.DefineExtensionType(2, function(value, options)
    return _serial.packers.Integer(false, value.r, 1) ..
        _serial.packers.Integer(false, value.g, 1) ..
        _serial.packers.Integer(false, value.b, 1) .. _serial.packers.Integer(false, value.a, 1)
end, function(stream, cursor, format, options)
    return Color(_serial.unpackers.Integer(false, stream, cursor, 1),
        _serial.unpackers.Integer(false, stream, cursor + 1, 1),
        _serial.unpackers.Integer(false, stream, cursor + 2, 1),
        _serial.unpackers.Integer(false, stream, cursor + 3, 1))
end, function(value)
    return IsColor(value)
end)

--- Entity
_serial.DefineExtensionType(3, function(value, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian
    return _serial.packers.Integer(false, value:EntIndex(), 2, swapEndianness)
end, function(stream, cursor, format, options)
    local swapEndianness = band(options, _serial.Option.LittleEndian) ~= _serial.Option.LittleEndian and
        _serial.isLittleEndian
    return Entity(_serial.unpackers.Integer(false, stream, cursor, 2, swapEndianness))
end, function(value)
    return isentity(value)
end)

--- Use this as a base index for defining your own extension types
_serial.UserExtensionTypeStart = 16

function MODULE:PreEnable()
    _G["serial"] = _serial
end

function MODULE:PostDisable()
    _G["serial"] = _serial
end

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
]] --
