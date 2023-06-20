
IMPLEMENTATION MODULE Variable;

FROM BIOS IMPORT
	Write, WriteString, WriteLn;
FROM LexDen IMPORT
	AbortFlag, WriteToken;
FROM Strings IMPORT
	Assign, CompareStr;
FROM UtyDen IMPORT
	WriteReal;
FROM Maths IMPORT
	PI, e;

CONST
	VarNameMax = 2;
	VarMax = 15;

TYPE
	ERROR = ( variable, undefine );
	VARNAME = ARRAY [ 0..VarNameMax ] OF CHAR;
	VARREC = RECORD
		Value: REAL;
		Name: VARNAME;
	END;

VAR
	Vars: INTEGER;
	VarRec: ARRAY [ 0..VarMax ] OF VARREC;
	p, q, r, s: INTEGER;

PROCEDURE VarError( code: ERROR );	(* âêÕÉGÉâÅ[ *)
BEGIN
	AbortFlag := TRUE
	WriteString( 'Variable Error, ' );
	CASE code OF
		variable:
			WriteString( 'Not enough memory.' )
	|	undefine:
			WriteString( 'Undefined Variable.' )
	END;
	WriteLn;
	WriteToken;
END VarError;

PROCEDURE FindVarName( VAR str: ARRAY OF CHAR ): INTEGER;
BEGIN
	p := 0;
	q := Vars;
	r := ( p + q ) DIV 2;
	WHILE p <= q DO
		s := CompareStr( str, VarRec[ r ].Name )
		IF s = 0 THEN
			RETURN r
		ELSIF s > 0 THEN
			p := r + 1
		ELSE
			q := r - 1
		END
		r := ( p + q ) DIV 2;
	END
	RETURN VarMax + 1;
END FindVarName;

PROCEDURE Assignment( v: REAL; str: ARRAY OF CHAR );
VAR
	i: INTEGER;
BEGIN
	i := FindVarName( str );
	IF i = VarMax + 1 THEN
		INC( Vars );
		IF Vars = VarMax + 1 THEN
			VarError( variable );
		END;
		FOR i := Vars TO p + 1 BY -1 DO
			VarRec[ i ] := VarRec[ i - 1 ];
		END;
		i := p;
		Assign( str, VarRec[ i ].Name )
	END;
	VarRec[ i ].Value := v;
END Assignment;

PROCEDURE Reference( VAR str: ARRAY OF CHAR ): REAL;
VAR
	i: CARDINAL;
BEGIN
	i := FindVarName( str );
	IF i = VarMax + 1 THEN
		VarError( undefine );
		RETURN 0;
	ELSE
		RETURN VarRec[ i ].Value;
	END;
END Reference;

PROCEDURE ListVars;
VAR
	i: INTEGER;
BEGIN
	FOR i := 0 TO Vars DO
		WriteString( VarRec[ i ].Name )
		WriteString( ": " )
		WriteReal( VarRec[ i ].Value );
		IF ( i MOD 3 = 2 ) OR ( i = Vars ) THEN
			WriteLn
		ELSE
			WriteString( ',  ' );
		END
	END
END ListVars;

PROCEDURE ClearVariables;
BEGIN
	VarRec[ 0 ].Name := "ans";
	VarRec[ 0 ].Value := 0;
	VarRec[ 1 ].Name := "e";
	VarRec[ 1 ].Value := e;
	VarRec[ 2 ].Name := "pi";
	VarRec[ 2 ].Value := PI;
	Vars := 2;
END ClearVariables;

BEGIN
	ClearVariables;
END Variable.

