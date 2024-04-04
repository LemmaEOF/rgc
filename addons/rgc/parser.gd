class_name ChartParser
extends Object

# parsing structure based on Crafting Interpreters
# this could definitely be done better,
# (I think this might actually be a regular language!),
# but it's Good Enough For Now!

enum TokenType {
	# single-char tokens
	LEFT_BRACE, RIGHT_BRACE, BREAK,
	# literals
	STRING, NUMBER,
	# keywords
	CHARTER, OFFSET, RATING, NOTES,
	# (lemma)eof
	EOF
}

class Token:
	extends RefCounted
	var type: TokenType
	var lexeme: String
	var literal: Variant
	var line: int
	
	func _init(type: TokenType, lexeme: String, literal: Variant, line: int):
		self.type = type
		self.lexeme = lexeme
		self.literal = literal
		self.line = line

#TODO: impl
static func parse(chart: String) -> Chart:
	var scanner: Scanner = Scanner.new(chart)
	var tokens: Array[Token] = scanner.scan()
	return null

class Scanner:
	extends RefCounted
	
	const _keywords = {
		"charter": TokenType.CHARTER,
		"offset": TokenType.OFFSET,
		"rating": TokenType.RATING,
		"notes": TokenType.NOTES
	}
	
	var _source: String
	var _tokens: Array[Token] = []
	var _start: int = 0
	var _current: int = 0
	var _line: int = 0
	
	func _init(source: String):
		self._source = source
	
	func scan() -> Array[Token]:
		while !_is_at_end():
			_start = _current
			_scan_token()
		_tokens.append(Token.new(TokenType.EOF, "", null, _line))
		return _tokens
	
	func _is_at_end() -> bool:
		return _current >= _source.length()
	
	func _scan_token() -> void:
		var c: String = _advance()
		match c:
			'{':
				_add_token(TokenType.LEFT_BRACE)
			'}':
				_add_token(TokenType.RIGHT_BRACE)
			';':
				_add_token(TokenType.BREAK)
			'#':
				while _peek() != '\n' and !_is_at_end():
					_advance()
			' ', '\r', '\t':
				pass
			'\n':
				_add_token(TokenType.BREAK)
				_line += 1
			'"':
				_string()
			'-':
				_negative_number()
			_:
				if c.is_valid_int():
					_number()
				elif _is_alpha(c):
					_identifier()
				else:
					printerr("Unexpected character '{}' on line {}".format([c, _line]))
	
	func _string() -> void:
		while _peek() != '"' and !_is_at_end():
			if _peek() == '\n':
				_line += 1
				_advance()
				
		if _is_at_end():
			printerr("Unterminated string ending at line {}".format(_line))
			return
		
		# closing quote
		_advance()
		
		var value: String = _source.substr(_start + 1, _current - 1)
		_add_token_l(TokenType.STRING, value)
		
	func _identifier() -> void:
		while _is_alphanumeric(_peek()):
			_advance()
		
		var value: String = _source.substr(_start, _current)
		if value in _keywords:
			_add_token(_keywords[value])
		else:
			_add_token_l(TokenType.STRING, value)
		
	func _number() -> void:
		var is_float = false
		
		while _peek().is_valid_int():
			_advance()
		
		if _peek() == '.' and _peek_next().is_valid_int():
			is_float = true
			_advance()
		
		while _peek().is_valid_int():
			_advance()
		
		if is_float:
			_add_token_l(TokenType.NUMBER, _source.substr(_start, _current).to_float())
		else:
			_add_token_l(TokenType.NUMBER, _source.substr(_start, _current).to_int())
	
	func _negative_number() -> void:
		var is_float = false
		_advance()

		while _peek().is_valid_int():
			_advance()

		if _peek() == '.' and _peek_next().is_valid_int():
			is_float = true
			_advance()

		while _peek().is_valid_int():
			_advance()

		if is_float:
			_add_token_l(TokenType.NUMBER, _source.substr(_start+1, _current).to_float() * -1)
		else:
			_add_token_l(TokenType.NUMBER, _source.substr(_start+1, _current).to_int() * -1)
	
	func _add_token(type: TokenType) -> void:
		_add_token_l(type, null)
	
	func _add_token_l(type: TokenType, literal: Variant) -> void:
		var text: String = _source.substr(_start, _current)
		_tokens.append(Token.new(type, text, literal, _line))
	
	func _advance() -> String:
		_current += 1
		return _source[_current]
	
	func _peek() -> String:
		if _is_at_end():
			return ""
		return _source[_current]
	
	func _peek_next() -> String:
		if _current + 1 >= _source.length():
			return ""
		return _source[_current+1]
	
	func _is_alpha(chr: String) -> bool:
		var code = chr.unicode_at(0)
		# A-Z, a-z, _
		return (code >= 0x41 && code <= 0x5A) or (code >= 0x61 && code <= 0x7a) or code == 0x5F
	
	func _is_alphanumeric(chr: String) -> bool:
		return chr.is_valid_int() or _is_alpha(chr)
