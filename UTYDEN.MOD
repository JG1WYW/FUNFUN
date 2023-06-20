
IMPLEMENTATION MODULE UtyDen;

FROM Maths IMPORT
	SQRT, ARCTAN, PI, EXP, LN, ENTIER;
FROM RealInOut IMPORT
	Engineering, Leadingplaces, WriteRealText, WriteRealFixedText, atoi;
FROM BIOS IMPORT
	Write, WriteString;
FROM Conversions IMPORT
	CardToString;

PROCEDURE ReadRealText( VAR Text: ARRAY OF CHAR; VAR r:REAL );
VAR
	I, J, K:INTEGER; 
	Scale: REAL; 
	Neg: BOOLEAN;
	Ch: CHAR;
	Minus: BOOLEAN;
BEGIN
	r := 0;
	J := 0;		(* J は数字列の先頭インデックス *)
	Minus := ( J <= HIGH( Text ) ) AND ( Text[ J ] = '-' );
	IF Minus OR ( Text[ J ] = '+' ) THEN
		INC( J )
	END;
	I := J;
	WHILE ( Text[ I ] >= '0' ) AND ( Text[ I ] <= '9' ) DO
		INC( I )
	END;
	IF Text[ I ] = '.' THEN
		INC( I );
		WHILE (I <= HIGH( Text )) AND (Text[I] >= '0') AND (Text[I] <= '9') DO
			INC( I )
		END;
	END;
	K := I;
	DEC( I );
    Scale := 1.0;
	IF Text[ I ] = '.' THEN
		DEC(I)
	END;
	WHILE I >= J DO
		r := r + Scale * ( ORD(Text[I]) - ORD('0') );
		Scale := 10.0 * Scale;
		DEC( I );
		IF ( I > 0 ) AND ( Text[ I ] = '.' ) THEN
			r := r / Scale;
			Scale := 1.0;
			DEC( I );
		END;
	END;
	
	(* 以上で小数点部が r に格納された *)
	
	IF ( K <= HIGH( Text ) ) AND ( CAP( Text[ K ] ) = 'E' ) THEN
		INC( K );
		IF K > HIGH( Text ) THEN
			RETURN
		END;
		Ch := Text[ K ];
		Neg := Ch = '-';
		IF Neg OR ( Ch = '+' ) THEN 
			INC( K );
		END;
		I := 0;
		WHILE (K <= HIGH(Text)) AND (Text[K] >= '0') AND (Text[K] <= '9') DO
			I := 10 * I + ( ORD(Text[K]) - ORD('0') ); 
			INC( K );
		END;
		IF Neg THEN
			I := -I;
		END
		
		(* 指数が I に格納された *)
		
		r := r * atoi( 10.0, I );
	END;
	IF Minus THEN
		r := -r
	END;
END ReadRealText;

PROCEDURE WriteRealCn( r: REAL );
VAR
	str: ARRAY [0..31] OF CHAR;
BEGIN
	WriteRealText( str, r, 19 );
	WriteString( str );
END WriteRealCn;

PROCEDURE WriteReal( r: REAL );
VAR
	e: INTEGER;
	str: ARRAY [0..31] OF CHAR;
BEGIN
	IF ( r <> 0.0 )  AND (( ABS( r ) >= 1.0e6 ) OR ( ABS( r ) < 1.0e-6 )) THEN
		WriteRealText( str, r, 19 );
	ELSE
		IF r < 0.0 THEN
			r := -r;
			Write( '-' );
		END
		IF r > 0.0 THEN
			e := 11 - ENTIER( LOG( r ) );
		ELSE
			e := 1;
		END
		IF e <= 0 THEN
			e := 1
		ELSIF e >= 11 THEN
			e := 11;
		END
		WriteRealFixedText( str, r, 0, e );
	END
	WriteString( str );
END WriteReal;

PROCEDURE WriteHex( r: REAL );
VAR
	i, j: INTEGER;
	str: ARRAY [ 0..7 ] OF CHAR;
BEGIN
	CardToString( LONGENTIER( r ), 16, str, j );
	FOR i := j + 1 TO 8 DO
		Write( '0' )
	END
	FOR i := HIGH( str ) + 1 - j TO HIGH( str ) DO
		Write( str[ i ] )
	END;
END WriteHex;

PROCEDURE WriteBin( r: REAL );
VAR
	i, j: INTEGER;
	str: ARRAY [ 0..31 ] OF CHAR;
BEGIN
	CardToString( LONGENTIER( r ), 2, str, j );
	FOR i := j + 1 TO 32 DO
		Write( '0' )
	END
	FOR i := HIGH( str ) + 1 - j TO HIGH( str ) DO
		Write( str[ i ] )
	END;
END WriteBin;

PROCEDURE WriteCard( i: CARDINAL );
VAR
	k, j: INTEGER;
	str: ARRAY [ 0..9 ] OF CHAR;
BEGIN
	CardToString( i, 10, str, j );
	FOR k := HIGH( str ) + 1 - j TO HIGH( str ) DO
		Write( str[ k ] )
	END;
END WriteCard;

PROCEDURE LONGENTIER( r: REAL ): LONGINT;
BEGIN
	IF r < 0.0 THEN
		RETURN -LONGTRUNC( -r )
	ELSE
		RETURN LONGTRUNC( r )
	END
END LONGENTIER;

PROCEDURE LOG( r: REAL ): REAL;
BEGIN
	RETURN LN( r ) * 0.43429448190325182
END LOG;

PROCEDURE ARCSIN( r: REAL ): REAL;
VAR
	n: REAL;
BEGIN
	IF r >= 1 THEN
		RETURN PI / 2
	ELSIF r <= -1 THEN
		RETURN -PI / 2
	END
	n := SQRT( 1 - r * r );
	RETURN ARCTAN( r / n )
END ARCSIN;

PROCEDURE ARCCOS( r: REAL ): REAL;
VAR
	n: REAL;
BEGIN
	IF r >= 1 THEN
		RETURN 0
	ELSIF r <= -1 THEN
		RETURN -PI
	END
	n := SQRT( 1 - r * r );
	n := ARCTAN( n / r )
	IF n < 0.0 THEN
		RETURN n + PI
	ELSE
		RETURN n
	END
END ARCCOS;

PROCEDURE SINH( r: REAL ): REAL;
BEGIN
	r := EXP( r );
	RETURN ( r - 1 / r ) / 2;
END SINH;

PROCEDURE COSH( r: REAL ): REAL;
BEGIN
	r := EXP( r );
	RETURN ( r + 1 / r ) / 2;
END COSH;

PROCEDURE TANH( r: REAL ): REAL;
BEGIN
	r := EXP( r );
	RETURN ( r - 1 / r ) / ( r + 1 / r );
END TANH;

BEGIN
	Leadingplaces := 0;
	Engineering := TRUE;
END UtyDen.

