
IMPLEMENTATION MODULE Dentaku;

FROM LexDen IMPORT
	Lex, AbortFlag, Token, Lptr, LexBuffer, ClearBuf, WriteToken,
	CLASS, ATTRIBUTE, STRING, TOKEN, RESERVED, OPERATOR;
FROM BIOS IMPORT
	PushScreen, PopScreen, ChangeScreen, PV,
	Write, WriteString, WriteLn, WSL;
FROM Maths IMPORT
	SQRT, SIN, COS, TAN, EXP, LN, ARCTAN;
FROM LongIntLogic IMPORT
	IOR, IAND;
FROM Variable IMPORT
	ListVars, Assignment, Reference, ClearVariables;
FROM UtyDen IMPORT
	ReadRealText, WriteReal, WriteRealCn, WriteHex, WriteBin, WriteCard,
	LONGENTIER, ARCSIN, ARCCOS, SINH, COSH, TANH, LOG;
FROM Inp IMPORT
	LineEdit;
FROM Ascii IMPORT
	AsciiLow, AsciiHigh;
FROM MSDOS IMPORT
	OFFSET;
FROM SYSTEM IMPORT
	ADR;

TYPE
	ERROR = ( expression, division, logarithm, squre, stack );

CONST
	LINKSIZE  = 4096;
	STACKSIZE = 65535 - LINKSIZE + 200;

PROCEDURE ReceivePacket;			(* LEX からのパケットを受け取る *)
BEGIN
	IF Token.Class <> LexEnd THEN
		Lex;
	END;
(*	WriteString( '"' );
	WriteString( Token.String );
	WriteString( '"' );
	WriteLn;
*)
END ReceivePacket;

PROCEDURE Through;
BEGIN
	WHILE Token.Class <> LexEnd DO
		Lex;
	END
END Through;

PROCEDURE MathError( code: ERROR );
BEGIN
	IF AbortFlag THEN
		RETURN
	END
	AbortFlag := TRUE
	WriteString( 'Math Error, ' );
	CASE code OF
		expression:
			WriteString('Invalid Expression.')
	|	division:
			WriteString('Division by zero.')
	|	logarithm:
			WriteString('Invalid Logarithm.')
	|	squre:
			WriteString('Invalid Exponent.')
	|	stack:
			WriteString('Stack Overflow.')
	END;
	WriteLn;
	WriteToken;
END MathError;

PROCEDURE WriteDMS( res: REAL );
VAR
	l: LONGCARD;
BEGIN
	l := LONGENTIER( res );
	WriteCard( SHORT( l DIV 3600 ) );
	Write( ':' );
	l := l MOD 3600;
	WriteCard( SHORT( l DIV 60 ) );
	Write( ':' );
	WriteCard( SHORT( l MOD 60 ) );
END WriteDMS;

PROCEDURE Expr(): REAL; FORWARD;	(* 使用コンパイラ固有の宣言 *)

(* ここから LL(1) に従う構文解析ルーチン *)

PROCEDURE E4(): REAL;
VAR
	res: REAL;
	func: RESERVED;
BEGIN
(*	WriteHex( FLOAT( OFFSET( ADR( func ) ) ) );
	WriteLn
*)
	IF OFFSET( ADR( func ) ) < STACKSIZE THEN
		MathError( stack );
		RETURN 0
	END;
	IF Token.Class = Int THEN
		res := FLOAT( Token.Integer )
	ELSIF Token.Class = Float THEN
		ReadRealText( Token.String, res )
	ELSIF (Token.Class = Operator) AND (Token.Ovalue = LeftSparen) THEN
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END;
		res := Expr();
		IF AbortFlag THEN
			RETURN 0
		END;
		IF NOT((Token.Class = Operator) AND (Token.Ovalue = RightSparen)) THEN
			MathError( expression );
			RETURN 0
		END
	ELSIF Token.Class = Ident THEN
		res := Reference( Token.String )
	ELSIF Token.Class = Reserved THEN
		func := Token.Rvalue;
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END;
		IF NOT( (Token.Class = Operator) AND (Token.Ovalue = LeftSparen) ) THEN
			MathError( expression );
			RETURN 0
		END
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END
		res := Expr();
		IF AbortFlag THEN
			RETURN 0
		END;
		IF NOT((Token.Class = Operator) AND (Token.Ovalue = RightSparen)) THEN
			MathError( expression );
			RETURN 0
		END
		CASE func OF
			Abs:	res := ABS( res )
		|	Sin:	res := SIN( res )
		|	Cos:	res := COS( res )
		|	Sinh:	res := SINH( res )
		|	Cosh:	res := COSH( res )
		|	Tan:	res := TAN( res )
		|	Tanh:	res := TANH( res )
		|	Asin:	res := ARCSIN( res )
		|	Acos:	res := ARCCOS( res )
		|	Atan:	res := ARCTAN( res )
		|	Exp:	res := EXP( res )
		|	Cn:
				WriteRealCn( res );
				WriteLn
		|	Hex:
				WriteHex( res );
				WriteLn
		|	Bin:
				WriteBin( res );
				WriteLn
		|	Dms:
				WriteDMS( res );
				WriteLn
		|	Sqrt:
				IF res <= 0.0 THEN
					MathError( squre )
				ELSE
					res := SQRT( res )
				END
		|	Ln:
				IF res <= 0.0 THEN
					MathError( logarithm )
				ELSE
					res := LN( res )
				END
		|	Log:
				IF res <= 0.0 THEN
					MathError( logarithm )
				ELSE
					res := LOG( res )
				END
		END
	ELSE
		MathError( expression );
		RETURN 0
	END;
	ReceivePacket;
	IF AbortFlag THEN
		RETURN 0
	END
	RETURN res;
END E4;

PROCEDURE E3(): REAL;
VAR
	res: REAL;
	flag: BOOLEAN;
BEGIN
	flag := TRUE;
	IF (Token.Class = Operator) AND ((Token.Ovalue=Plus) OR (Token.Ovalue=Minus)) THEN
		IF Token.Ovalue = Minus THEN
			flag := FALSE
		END;
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END
	END
	res := E4();
	IF AbortFlag THEN
		RETURN 0
	END;
	IF flag THEN
		RETURN res
	ELSE
		RETURN -res
	END
END E3;

PROCEDURE E2(): REAL;
VAR
	res, tmp: REAL;
	flag: BOOLEAN;
BEGIN
	res := E3()
	IF AbortFlag THEN
		RETURN 0
	END;
	flag := TRUE;
	IF (Token.Class = Operator) AND (Token.Ovalue=Hat) THEN
		flag := FALSE
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END
		tmp := E3();
		IF AbortFlag THEN
			RETURN 0
		END
	END
	IF flag THEN
		RETURN res
	ELSE
		IF res <= 0.0 THEN
			MathError( squre )
			RETURN 0
		ELSE
			RETURN EXP( tmp * LN( res ) )	(* res^tmp *)
		END
	END
END E2;

PROCEDURE E1(): REAL;
VAR
	res, tmp: REAL;
	op: OPERATOR;
BEGIN
	res := E2();
	IF AbortFlag THEN
		RETURN 0
	END;
	WHILE Token.Attribute = Mulop DO
		op := Token.Ovalue;
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END;
		tmp := E2();
		IF AbortFlag THEN
			RETURN 0
		END;
		CASE op OF
			Asterisk:
				res := res * tmp
		|	Slash:
				IF tmp = 0.0 THEN
					MathError( division )
				ELSE
					res := res / tmp
				END
		|	Ampersand:
				res := FLOAT( IAND(LONGENTIER(res),LONGENTIER(tmp)) )|
		END
	END
	RETURN res;
END E1;

PROCEDURE Expr(): REAL;
VAR
	res, tmp: REAL;
	op: OPERATOR;
BEGIN
	res := E1();
	IF AbortFlag THEN
		RETURN 0
	END;
	WHILE Token.Attribute = Addop DO
		op := Token.Ovalue;
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END;
		tmp := E1();
		IF AbortFlag THEN
			RETURN 0
		END;
		CASE op OF
			Plus:	res := res + tmp
		|	Minus:	res := res - tmp
		|	Bar:	res := FLOAT( IOR(LONGENTIER(res),LONGENTIER(tmp)) )|
		END
	END
	RETURN res;
END Expr;

PROCEDURE Stmts(): REAL;
VAR
	res: REAL;
BEGIN
	res := Expr();
	IF AbortFlag THEN
		RETURN 0
	END;
	IF (Token.Class = Operator) AND (Token.Ovalue = Equal) THEN
		ReceivePacket;
		IF AbortFlag THEN
			RETURN 0
		END;
		IF Token.Class = Ident THEN
			Assignment( res, Token.String );
			Token.Class := LexEnd;
		END
	END
	Assignment( res, "ans" );
	RETURN res;
END Stmts;

PROCEDURE Dentaku;
VAR
	res: REAL;
BEGIN
	PushScreen;
	
	WSL( "FUN FUN V.3.141 Copyright (C) 1993, 1994 by tar. Bindings are Emacs like." )
	WSL( "Window up down: '<','>', Show Variables: '?', Clear: '#', ASCII code: '@','!'" )
	
	Token.String := "ans";
	WriteReal( Reference( Token.String ) );
	WriteLn;
	
	LOOP
		AbortFlag := FALSE;
		REPEAT
			WriteString( "% " );
			IF NOT LineEdit( LexBuffer ) THEN
				WriteLn;
				EXIT;
			END
			WriteLn;
			CASE LexBuffer[ 0 ] OF
			|	'?':
					ListVars;
					LexBuffer[ 0 ] := 0x
			|	'@':
					AsciiLow;
					LexBuffer[ 0 ] := 0x
			|	'!':
					AsciiHigh;
					LexBuffer[ 0 ] := 0x
			|	'#':
					ClearVariables;
					LexBuffer[ 0 ] := 0x
			|	'>':
					ChangeScreen( down )
			|	'<':
					ChangeScreen( up )
			END
		UNTIL LexBuffer[ 0 ] <> 0x;
		Lptr := 0;
		Token.Class := Arbitary;	(* dummy *)
		ReceivePacket;
		IF Token.Class <> LexEnd THEN
			res := Stmts();
			IF NOT AbortFlag THEN
				WriteReal( res );
				WriteLn
			END
			IF Token.Class <> LexEnd THEN
				MathError( expression )
			END
		END
		Through
		ClearBuf;
	END
	
	PopScreen;
END Dentaku;

END Dentaku.
