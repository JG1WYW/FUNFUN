
IMPLEMENTATION MODULE Inp;

(*	ラインエディットモデュール. 英数字バージョン. 漢字不可	*)

FROM BIOS IMPORT
	GetChar, Write, WriteString, WriteStringPos, GoLeft, GoRight, KillRight;

CONST
	BUFFERSIZE = 72;
	HISTORY = 5;

VAR
	History: ARRAY [ 0..HISTORY ],[ 0..BUFFERSIZE ] OF CHAR;

PROCEDURE StrLen( VAR str: ARRAY OF CHAR; p: CARDINAL ): CARDINAL;
VAR
	i: CARDINAL;
BEGIN
	i := 0;
	WHILE p <= HIGH( str ) DO
		IF str[ p ] = 0x THEN
			RETURN i;
		ELSE
			INC( p );
			INC( i );
		END
	END
	RETURN i;
END StrLen;

PROCEDURE StrCopy( VAR dst, src: ARRAY OF CHAR; dp, sp: CARDINAL );
VAR
	i: INTEGER;
BEGIN
	IF sp >= dp THEN
		LOOP
			dst[ dp ] := src[ sp ];
			IF src[ sp ] = 0x THEN
				EXIT
			END
			INC( dp );
			INC( sp );
		END
	ELSE
		i := StrLen( src, sp );
		INC( sp, i );
		INC( dp, i );
		LOOP
			dst[ dp ] := src[ sp ];
			DEC( dp );
			DEC( sp );
			IF i = 0 THEN
				EXIT
			END
			DEC( i );
		END
	END
END StrCopy;

PROCEDURE LineEdit( VAR str: ARRAY OF CHAR ): BOOLEAN;
VAR
	ch: CHAR;
	i, ptr, eptr, tptr, hptr: INTEGER;
	cptr: ARRAY [0..1] OF CHAR;
BEGIN
	hptr := HISTORY;
	ptr := StrLen( str, 0 );
	eptr := ptr;
	WriteString( str );
	LOOP
		ch := GetChar();
		CASE ch OF
(* ESC, C-c, C-g *)
			01bx, 03x, 07x:
				RETURN FALSE
(* C-m *)
		|	0dx:
				str[ ptr ] := 0x;
				FOR ptr := 0 TO HISTORY-2 DO
					StrCopy( History[ ptr ], History[ ptr + 1 ], 0, 0 );
				END
				StrCopy( History[ HISTORY-1 ], str, 0, 0 );
				RETURN TRUE
(* C-n *)
		|	0ex:
				IF hptr + 1 <= HISTORY THEN
					INC( hptr );
					StrCopy( str, History[ hptr ], 0, 0 );
					IF ptr > 0 THEN
						GoLeft( ptr );
					END
					ptr := StrLen( str, 0 );
					eptr := ptr;
					WriteString( str );
					KillRight
				END
(* C-p *)
		|	010x:
				IF hptr - 1 >= 0 THEN
					DEC( hptr );
					StrCopy( str, History[ hptr ], 0, 0 );
					IF ptr > 0 THEN
						GoLeft( ptr );
					END
					ptr := StrLen( str, 0 );
					eptr := ptr;
					WriteString( str );
					KillRight
				END
(* C-k *)
		|	0bx:
				KillRight;
				str[ ptr ] := 0x;
				eptr := ptr
(* C-h *)
		|	08x:
				IF ptr > 0 THEN
					tptr := ptr;
					DEC( ptr ); DEC( eptr );
					i := 1; cptr := " ";
					StrCopy( str, str, ptr, tptr );
					GoLeft( tptr - ptr );
					WriteStringPos( str, ptr );
					WriteString( cptr );
					GoLeft( CARDINAL( i ) + StrLen( str, ptr ) );
				END
(* C-d *)
		|	04x:
				IF ptr < eptr THEN
					tptr := ptr;
					INC( tptr ); DEC( eptr );
					i := 1; cptr := " ";
					StrCopy( str, str, ptr, tptr );
					WriteStringPos( str, ptr );
					WriteString( cptr );
					GoLeft( CARDINAL( i ) + StrLen( str, ptr ) );
				END
(* C-f *)
		|	06x:
				IF ptr < eptr THEN
					INC( ptr ); GoRight( 1 );
				END
(* C-b *)
		|	02x:
				IF ptr > 0 THEN
					DEC( ptr ); GoLeft( 1 );
				END
(* C-e *)
		|	05x:
				IF ptr < eptr THEN
					GoRight( eptr - ptr ); ptr := eptr
				END
(* C-a *)
		|	01x:
				IF ptr > 0 THEN
					GoLeft( ptr ); ptr := 0;
				END
(*文字*)
		ELSE
			IF ( ch >= ' ' ) AND ( eptr < BUFFERSIZE ) THEN
				StrCopy( str, str, ptr+1, ptr );
				str[ ptr ] := ch;
				Write( ch );
				INC( ptr ); INC( eptr );
				WriteStringPos( str, ptr );
				i := eptr - ptr;
				IF 0 < i THEN
					GoLeft( i );
				END
			END
		END
	END
END LineEdit;

VAR
	i: INTEGER;
BEGIN
	FOR i := 0 TO HISTORY DO
		History[ i ][ 0 ] := 0x;
	END
END Inp.
