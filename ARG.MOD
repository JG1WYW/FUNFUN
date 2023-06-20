
(*	コマンドライン・パラメータ取得モデュール	*)

IMPLEMENTATION MODULE Arg;

FROM SYSTEM IMPORT ADR, ADDRESS;
FROM MsDos IMPORT Int, Registers;
FROM LOADER IMPORT ProgPrefixAddress;

VAR
	Argument: ARRAY [0..127] OF CHAR;

PROCEDURE SetPSCh();
VAR
	regs: Registers;
BEGIN
	regs.AH := 37h;
	regs.AL := 00h;
	Int( 21h, regs );
	PSCh := CHAR( regs.DL );
END SetPSCh;

PROCEDURE SetArgs();
VAR
	c: CHAR;
	flag: BOOLEAN;
	i, Length: CARDINAL;
	ptr: ADDRESS;
BEGIN
	Argv[ 0 ] := NIL;
	Argc := 1;
	Length := ORD( ProgPrefixAddress^.CommText[ -1 ] );
	IF 0 < Length THEN
		flag := FALSE;
		ptr := ADR( Argument );
		FOR i := 0 TO Length - 1 DO
			c := ProgPrefixAddress^.CommText[ i ];
			IF ' ' <> c THEN
				IF FALSE = flag THEN
					flag := TRUE;
					Argv[ Argc ] := ptr;
					IF Argc < ARGS THEN
						INC( Argc );
					END;
				END;
				ptr^ := c;
				INC( ptr );
				ptr^ := 0x;
			ELSIF ' ' = c THEN
				IF TRUE = flag THEN
					flag := FALSE;
					INC( ptr );
				END;
			END;
		END;
	END;
	Argv[ Argc ] := NIL;
	DEC( Argc );
END SetArgs;

BEGIN
	SetPSCh();
	SetArgs();
END Arg.
