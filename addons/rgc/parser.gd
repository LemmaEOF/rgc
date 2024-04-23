class_name ChartParser
extends Object

# parsing structure based on Crafting Interpreters
# this could definitely be done better,
# (I think this might actually be a regular language!),
# but it's Good Enough For Now!

# TODO: actual error-handling instead of just printing an error and continuing
# TODO: document and clean up this mess
# TODO: spin out impl classes to separate files?

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

static func parse(chart: String) -> Chart:
	var scanner: Scanner = Scanner.new(chart)
	var tokens: Array[Token] = scanner.scan()
	var parser: Parser = Parser.new(tokens)
	return parser.parse()

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

class Parser:
	extends RefCounted
	
	var _tokens: Array[Token]
	var _current: int = 0
	
	var _charter: String
	var _offset: float
	var _rating: float
	var _notes: Array[Note] = []
	
	func _init(tokens: Array[Token]):
		self._tokens = tokens
	
	func parse() -> Chart:
		while !_is_at_end(): # TODO: is this what I want?
			_parse_property()
			_consume(TokenType.BREAK)
		if _charter == null:
			printerr("Chart does not define charter")
			return null
		if _offset == null:
			printerr("Chart does not define offset")
			return null
		if _rating == null:
			printerr("Chart does not define rating")
			return null
		if _notes.size() == 0:
			printerr("Chart has no notes")
			return null
		return Chart.new(_charter, _offset, _rating, _notes)
	
	func _parse_property() -> void:
		var t = _peek()
		match t.type:
			TokenType.CHARTER:
				var val = _consume(TokenType.STRING)
				if val == null or !(val is String):
					printerr("Bad value type for charter at line {} - expected string, got {}".format([t.line, t.lexeme]))
				else:
					_charter = val as String
			TokenType.OFFSET:
				var val = _consume(TokenType.NUMBER)
				if val == null or !(val is float or val is int):
					printerr("Bad value type for offset at line {} - expected float, got {}".format([t.line, t.lexeme]))
				else:
					_offset = val as float
			TokenType.RATING:
				var val = _consume(TokenType.NUMBER)
				if val == null or !(val is float or val is int):
					printerr("Bad value type for rating at line {} - expected float, got {}".format([t.line, t.lexeme]))
				else:
					_rating = val as float
			TokenType.NOTES:
				_parse_notes()
			TokenType.BREAK:
				pass
			_:
				printerr("Unexpected token {} for top-level property at line {}: must be charter, offset, rating, or notes".format([t.lexeme, t.line]))
	
	func _parse_notes() -> void:
		_consume(TokenType.LEFT_BRACE)
		_consume(TokenType.BREAK)
		while !_is_at_end() and !_match([TokenType.RIGHT_BRACE]):
			_parse_note()
		_advance()
	
	func _parse_note() -> void:
		var type_name = _consume(TokenType.STRING) as String
		var type = NoteType.get_type(type_name)
		if type == null:
			printerr("Note type {} not registered".format(type_name))
			_seek(TokenType.BREAK)
		else:
			var beat = _consume(TokenType.NUMBER) as float
			var args: Array = []
			while _match([TokenType.STRING, TokenType.NUMBER]):
				args.append(_peek().literal)
			if args.size() < type.get_minimum_arguments():
				printerr("Not enough arguments for note type {}: required {}, got {}".format([type_name, type.get_minimum_arguments(), args.size()]))
			_notes.append(Note.new(type, beat, args))
			_consume(TokenType.BREAK)
	
	func _match(types: Array[TokenType]) -> bool:
		for type in types:
			if _check(type):
				_advance()
				return true
		return false
	
	func _check(type: TokenType) -> bool:
		if _is_at_end():
			return false
		return _peek().type == type
	
	func _advance() -> Token:
		if !_is_at_end():
			_current += 1
		return _previous()
	
	func _is_at_end() -> bool:
		return _peek().type == TokenType.EOF
	
	func _peek() -> Token:
		return _tokens[_current]
	
	func _previous() -> Token:
		return _tokens[_current-1]
	
	func _consume(type: TokenType) -> Variant:
		if _check(type):
			return _advance().literal
		return null
	
	func _seek(type: TokenType) -> void:
		while !_is_at_end() and !_match([type]):
			_advance()
