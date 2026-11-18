class GameEventsPublisherHelper extends Object;

static function string CreateJsonPairAsInt(string key, int value) {
    return "\""$key$"\":"@value;
}

static function string CreateJsonPairAsBool(string key, bool value) {
    return "\""$key$"\":"@ConvertIntoJsonBool(value);
}

static function string CreateJsonPairAsString(string key, string value) {
    return "\""$key$"\":"@WrapIntoJsonString(value);
}

static function string WrapIntoJsonString(string value) {
    return "\""$EscapeJsonString(value)$"\"";
}

// Escapes a string so it can be placed between the quotes of a JSON string.
//
// The output is pure ASCII on purpose: raw control characters are not legal inside a JSON
// string, and the Submitter declares no charset, so raw high bytes depend on how the receiver
// guesses the encoding. Everything outside printable ASCII is sent as \uXXXX instead.
//
// Names arrive in whatever encoding the player's client used. UT 469 clients send UTF-8, while
// older clients send single-byte Latin-1. So each byte at or above 0xC2 is first tried as the
// start of a valid UTF-8 sequence, which is decoded into a single code point (the two bytes
// C3 A2 become U+00E2). Anything that is not valid UTF-8 falls back to Latin-1, one byte per
// code point (the single byte E2 also becomes U+00E2). Both encodings of the same name
// therefore publish the same JSON.
// Known ambiguity: a Latin-1 name that happens to form a valid UTF-8 sequence (for example the
// two characters with codes C3 and A2) is decoded as UTF-8.
//
// NOTE: UnrealScript has no "\n", "\r", "\t", "\b" or "\f" escapes in string literals
// ("\n" is just the letter n), so characters are matched by their Asc() code, never by literal.
static function string EscapeJsonString(string value) {
    local string result;
    local int i, c, seqLen, codePoint;

    for (i = 0; i < Len(value); i++) {
        c = ByteAt(value, i);
        seqLen = 0;
        if (c >= 194 && c <= 244) {
            seqLen = DecodeUtf8(value, i, c, codePoint);
        }

        if (seqLen > 0) {
            if (codePoint > 65535) {
                // Outside the BMP: JSON needs a UTF-16 surrogate pair.
                codePoint -= 65536;
                result = result $ "\\u" $ ToHex4(55296 + (codePoint >> 10)) $ "\\u" $ ToHex4(56320 + (codePoint & 1023));
            } else {
                result = result $ "\\u" $ ToHex4(codePoint);
            }
            i += seqLen - 1; // Skip the continuation bytes.
        } else if (c == 34) {
            result = result $ "\\\"";
        } else if (c == 92) {
            result = result $ "\\\\";
        } else if (c == 8) {
            result = result $ "\\b";
        } else if (c == 9) {
            result = result $ "\\t";
        } else if (c == 10) {
            result = result $ "\\n";
        } else if (c == 12) {
            result = result $ "\\f";
        } else if (c == 13) {
            result = result $ "\\r";
        } else if (c < 32 || c > 126 || c == 37) {
            // Control, non-ASCII (Latin-1 fallback), and '%' (so a name can't inject a %Token% into
            // the JSON templates).
            result = result $ "\\u" $ ToHex4(c);
        } else {
            result = result $ Mid(value, i, 1);
        }
    }
    return result;
}

// Returns the character at index i as an unsigned value.
static function int ByteAt(string value, int i) {
    local int c;

    c = Asc(Mid(value, i, 1));
    if (c < 0) {
        c += 256; // Some builds return a signed char for bytes above 127.
    }
    return c;
}

// Tries to decode a UTF-8 sequence whose lead byte is at index i. Returns its length in bytes
// and sets codePoint, or returns 0 if it isn't valid UTF-8 (bad or missing continuation bytes,
// overlong form, UTF-16 surrogate, or beyond U+10FFFF).
static function int DecodeUtf8(string value, int i, int lead, out int codePoint) {
    local int seqLen, k, b, minValue;

    if (lead >= 194 && lead <= 223) {
        seqLen = 2;
        codePoint = lead & 31;
        minValue = 128;
    } else if (lead >= 224 && lead <= 239) {
        seqLen = 3;
        codePoint = lead & 15;
        minValue = 2048;
    } else if (lead >= 240 && lead <= 244) {
        seqLen = 4;
        codePoint = lead & 7;
        minValue = 65536;
    } else {
        return 0;
    }

    if (i + seqLen > Len(value)) {
        return 0;
    }
    for (k = 1; k < seqLen; k++) {
        b = ByteAt(value, i + k);
        if (b < 128 || b > 191) {
            return 0;
        }
        codePoint = (codePoint << 6) | (b & 63);
    }

    if (codePoint < minValue || codePoint > 1114111 || (codePoint >= 55296 && codePoint <= 57343)) {
        return 0;
    }
    return seqLen;
}

static function string ToHex4(int value) {
    local string digits;

    digits = "0123456789ABCDEF";
    return Mid(digits, (value >> 12) & 15, 1) $ Mid(digits, (value >> 8) & 15, 1) $ Mid(digits, (value >> 4) & 15, 1) $ Mid(digits, value & 15, 1);
}

static function string ConvertIntoJsonBool(bool value) {
    local string temp;
    temp = "false";
    if (value) {
        temp = "true";
    }
    return temp;
}

static function string Replace(string Text, string Match, string Replacement)
{
	local int i;
	
	i = InStr(Text, Match);	

	if(i != -1)
		return Left(Text, i) $ Replacement $ Replace(Mid(Text, i+Len(Match)), Match, Replacement);
	else
		return Text;
}

//
// Returns the string representation of the name of an object without the package
// prefixes.
//
static function String GetItemName( string FullName )
{
	local int pos;

	pos = InStr(FullName, ".");
	While ( pos != -1 )
	{
		FullName = Right(FullName, Len(FullName) - pos - 1);
		pos = InStr(FullName, ".");
	}

	return FullName;
}

defaultproperties
{
}
