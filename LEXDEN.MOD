
(*	Žš‹å‰ðÍƒ‹[ƒ`ƒ“	*)

IMPLEMENTATION MODULE LexDen;

FROM Strings IMPORT
	CompareStr;
FROM BIOS IMPORT
	WriteString, WriteStringPos, Write, WriteLn;

CONST
	FuncMax = ORD( MAX( RESERVED ) );

TYPE
	CharType = ( delimiter, number, alphabet );
	ERROR = ( escape, literal );
	CHARS = [ 20x..7fx ];
	CSET = SET OF CHARS;

VAR
	CharTypeTable: ARRAY CHARS OF CharType;
	FuncName: ARRAY [ 0..FuncMax ],[ 0..3 ] OF CHAR;

PROCEDURE ClearBuf;
VAR
	i: CARDINAL;
BEGIN
	FOR i := 0 TO HIGH( LexBuffer ) DO
		LexBuffer[ i ] := 0x;
	END
END ClearBuf;

PROCEDURE FatalError;
BEGIN
	LexBuffer := "Sorry, fatal error occured. Now, Ready to calculate."
END FatalError;

PROCEDURE WriteToken;
VAR
	i: INTEGER;
BEGIN
	Write( '"' );
	WriteString( Token.String );
	WriteString( '" ' );
	WriteStringPos( LexBuffer, Lptr );
	WriteLn
END WriteToken;

PROCEDURE SyntaxError( code: ERROR );
BEGIN
	AbortFlag := TRUE;
	WriteString( 'Syntax Error, ' );
	CASE code OF
		literal:
			WriteString( 'Invalid Literal.' )
	END;
	WriteLn;
END SyntaxError;

PROCEDURE GetChar():CHAR;
VAR
	Ch: CHAR;
BEGIN
	REPEAT
		Ch := LexBuffer[ Lptr ];
		INC( Lptr );
		IF Ch = 0x THEN
			Ch := 7fx
		END
	UNTIL ( ( Ch >= 20x ) AND ( Ch < 080x ) );
	RETURN Ch
END GetChar;

PROCEDURE UnGetChar;
BEGIN
	IF Lptr > 0 THEN
		DEC( Lptr )
	END
END UnGetChar;

PROCEDURE FindFuncName( VAR str: ARRAY OF CHAR ): CARDINAL;
VAR
	p, q, r, s: INTEGER;
BEGIN
	p := 0;
	q := FuncMax;
	r := ( p + q ) DIV 2;
	WHILE p <= q DO
		s := CompareStr( str, FuncName[ r ] )
		IF s = 0 THEN
			RETURN CARDINAL( r )
		ELSIF s > 0 THEN
			p := r + 1
		ELSE
			q := r - 1
		END
		r := ( p + q ) DIV 2;
	END
	RETURN FuncMax + 1;
END FindFuncName;

PROCEDURE ID( Ch: CHAR );
VAR
	ptr: CARDINAL;
BEGIN
	ptr := 0;
	WITH Token DO
		String[ 0 ] := Ch;
		REPEAT
			INC( ptr );
			Ch := GetChar();
			String[ ptr ] := Ch;
		UNTIL delimiter = CharTypeTable[ Ch ];
		String[ ptr ] := 0x;
		Class := Ident;
		ptr := FindFuncName( String );
		IF ptr <> FuncMax + 1 THEN
			Class := Reserved;
			Rvalue := VAL( RESERVED, ptr );
		END
		UnGetChar;
	END;
END ID;

PROCEDURE TextAtoC(): CARDINAL;
VAR
	i, ptr: CARDINAL;
BEGIN
	i := 0;
	ptr := 0;
	WITH Token DO
		WHILE (String[ptr] <> 0x) AND (number = CharTypeTable[String[ptr]]) DO
			i := i * 10 + ORD( String[ ptr ] ) - 48;
			INC( ptr );
		END;
	END;
	RETURN i;
END TextAtoC;

PROCEDURE Decimal( Ch: CHAR ): CARDINAL;
BEGIN
	Ch := CAP( Ch );
	IF (Ch >= 'A') AND (Ch <= 'F') THEN
		RETURN ORD(Ch) - 55;
	ELSIF number = CharTypeTable[ Ch ] THEN
		RETURN ORD(Ch) - 48;
	ELSE
		RETURN 65535;
	END;
END Decimal;

PROCEDURE Numeric( Ch: CHAR );
VAR
	i, ptr, base: CARDINAL;
BEGIN
	ptr := 0;
	WITH Token DO
		Class := Float;
		String[ 0 ] := Ch;
		REPEAT
			INC( ptr );
			Ch := GetChar();
			String[ ptr ] := Ch;
		UNTIL number <> CharTypeTable[ Ch ];
		IF '_' = Ch THEN
			Class := Int;
			base := TextAtoC();
			Integer := 0;
			REPEAT
				INC( ptr );
				Ch := GetChar();
				IF delimiter <> CharTypeTable[ Ch ] THEN
					i := Decimal( Ch );
					IF ( i >= 0 ) AND ( i <= base ) THEN
						Integer := Integer * base + i;
						String[ ptr ] := Ch;
					ELSE
						SyntaxError( literal );
					END;
				END;
			UNTIL delimiter = CharTypeTable[ Ch ];
			String[ ptr ] := 0x;
			UnGetChar;
			RETURN;
		ELSIF Ch = ':' THEN
			Class := Int;
			Integer := LONG( TextAtoC() );
			WHILE Ch = ':' DO
				Integer := Integer * 60;
				base := 0;
				REPEAT
					INC( ptr );
					Ch := GetChar();
					IF number = CharTypeTable[ Ch ] THEN
						base := base * 10 + ORD( Ch ) - ORD( '0' );
					END
				UNTIL number <> CharTypeTable[ Ch ];
				Integer := Integer + base;
			END
			String[ ptr ] := 0x;
			UnGetChar;
			RETURN;
		END
		IF Ch = '.' THEN
			INC( ptr );
			Ch := GetChar();
			String[ ptr ] := Ch;
			IF number = CharTypeTable[ Ch ] THEN
				REPEAT
					INC( ptr );
					Ch := GetChar();
					String[ ptr ] := Ch;
				UNTIL number <> CharTypeTable[ Ch ];
			ELSE
				SyntaxError( literal );
			END;
		END
		IF CAP( Ch ) = 'E' THEN
			INC( ptr );
			Ch := GetChar();
			String[ ptr ] := Ch;
			IF (Ch = '+') OR (Ch = '-') OR (number = CharTypeTable[ Ch ]) THEN
				REPEAT
					INC( ptr );
					Ch := GetChar();
					String[ ptr ] := Ch;
				UNTIL number <> CharTypeTable[ Ch ];
			ELSE
				SyntaxError( literal );
			END;
		END;
		String[ ptr ] := 0x;
		UnGetChar;
	END;
END Numeric;

PROCEDURE Special( Ch: CHAR );
BEGIN
	WITH Token DO
		Class := Operator;
		String[ 0 ] := Ch;
		String[ 1 ] := 0x;
		CASE Ch OF
			'+':
				Attribute := Addop;
				Ovalue := Plus
		|	'-':
				Attribute := Addop;
				Ovalue := Minus
		|	'|':
				Attribute := Addop;
				Ovalue := Bar
		|	'*':
				Attribute := Mulop;
				Ovalue := Asterisk
		|	'/':
				Attribute := Mulop;
				Ovalue := Slash
		|	'&':
				Attribute := Mulop;
				Ovalue := Ampersand
		|	'^':
				Attribute := Mulop;
				Ovalue := Hat
		|	'=':
				Attribute := Relop;
				Ovalue := Equal
		|	'(':
				Ovalue := LeftSparen
		|	')':
				Ovalue := RightSparen
		END
	END;
END Special;

PROCEDURE Lex;
VAR
	Ch: CHAR;
BEGIN
	Token.Class := Arbitary;
	Token.Attribute := NonAttr;
	REPEAT
		Ch := GetChar();
		IF ( Ch >= '0' ) AND ( Ch <= '9' ) THEN
			Numeric( Ch );
		ELSIF Ch IN CSET { '+', '-', '|', '*', '/', '&', '^', '=', '(', ')' } THEN
			Special( Ch );
		ELSIF (( Ch >= 'a' ) AND ( Ch <= 'z' )) OR (( Ch >= 'A' ) AND ( Ch <= 'Z' )) OR ( Ch = '_' ) THEN
			ID( Ch );
		ELSIF Ch = 7fx THEN
			Token.String[ 0 ] := 0x;
			Token.Class := LexEnd;
		END
	UNTIL Token.Class <> Arbitary;
END Lex;

VAR
	Ch: CHAR;
BEGIN
	ClearBuf;
	
	FOR Ch := 20x TO 07fx DO
		CharTypeTable[ Ch ] := delimiter;
	END;
	
	FOR Ch := 'A' TO 'Z' DO
		CharTypeTable[ Ch ] := alphabet;
	END;
	FOR Ch := 'a' TO 'z' DO
		CharTypeTable[ Ch ] := alphabet;
	END;
	
	CharTypeTable[ '_' ] := alphabet;
	
	FOR Ch := '0' TO '9' DO
		CharTypeTable[ Ch ] := number;
	END;
	
	FuncName[ ORD( Abs ) ] := 'abs';
	FuncName[ ORD( Acos ) ] := 'acos';
	FuncName[ ORD( Asin ) ] := 'asin';
	FuncName[ ORD( Atan ) ] := 'atan';
	FuncName[ ORD( Bin ) ] := 'bin';
	FuncName[ ORD( Cn ) ] := 'cn';
	FuncName[ ORD( Cos ) ] := 'cos';
	FuncName[ ORD( Cosh ) ] := 'cosh';
	FuncName[ ORD( Dms ) ] := 'dms';
	FuncName[ ORD( Exp ) ] := 'exp';
	FuncName[ ORD( Hex ) ] := 'hex';
	FuncName[ ORD( Ln ) ] := 'ln';
	FuncName[ ORD( Log ) ] := 'log';
	FuncName[ ORD( Sin ) ] := 'sin';
	FuncName[ ORD( Sinh ) ] := 'sinh';
	FuncName[ ORD( Sqrt ) ] := 'sqrt';
	FuncName[ ORD( Tan ) ] := 'tan';
	FuncName[ ORD( Tanh ) ] := 'tanh';
	
END LexDen.
