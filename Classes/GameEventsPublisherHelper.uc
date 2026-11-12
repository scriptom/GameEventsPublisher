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
// The output is pure ASCII on purpose. UnrealScript strings are single-byte (Latin-1 /
// the server's code page) and the Submitter declares no charset, so raw bytes above 0x7F
// would be decoded as (invalid) UTF-8 by the receiver, and raw control characters are not
// legal inside a JSON string at all. Every such character is sent as \u00XX instead.
//
// NOTE: UnrealScript has no "\n", "\r", "\t", "\b" or "\f" escapes in string literals
// ("\n" is just the letter n), so characters are matched by their Asc() code, never by literal.
static function string EscapeJsonString(string value) {
    local string result;
    local int i, c;

    for (i = 0; i < Len(value); i++) {
        c = Asc(Mid(value, i, 1));
        if (c < 0) {
            c += 256; // Some builds return a signed char for bytes above 127.
        }

        if (c == 34) {
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
            // Control, non-ASCII, and '%' (so a name can't inject a %Token% into the JSON templates).
            result = result $ "\\u" $ ToHex4(c);
        } else {
            result = result $ Mid(value, i, 1);
        }
    }
    return result;
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
