
(*	BIOS handling	*)

IMPLEMENTATION MODULE BIOS;

FROM SYSTEM IMPORT BYTE, ADDRESS;
FROM MSDOS IMPORT Int, Registers, MakePointer;
FROM FastMove IMPORT Movedown;

(* アトリビュート
	黒			001h
	青			021h
	赤			041h
	マゼンタ	061h
	緑			081h
	シアン		0a1h
	黄色		0c1h
	白			0e1h
*)

CONST
	DLINES = 8;						(* ふぁんふぁんのウィンドウの大きさ *)
	ATTRIBUTE = 0e1h;				(* 文字色 *)
	REVERSE   = ATTRIBUTE + 4;		(* それに対応した反転色 *)

VAR
	OldX, OldY, PosX, PosY: BYTE;
	Base: BYTE = 0;
	Base160: CARDINAL;
	posX[ 0060h : 011ch ]: BYTE;
	posY[ 0060h : 0110h ]: BYTE;
	i, j: INTEGER;
	ptr: ADDRESS;
	regs: Registers;
	CharWork: ARRAY [ 0..160 * ( DLINES + 1 ) - 1 ] OF BYTE;
	AttrWork: ARRAY [ 0..80 * ( DLINES + 1 ) - 1 ] OF BYTE;

PROCEDURE SetPos( x, y: BYTE );
BEGIN
	regs.AH := 13h;
	regs.DX := CARDINAL( x ) * 2 + CARDINAL( y ) * 160;
	Int( 18h, regs );
	posX := x;
	posY := y;
END SetPos;

PROCEDURE SetCur( x, y: BYTE );
BEGIN
	ptr := MakePointer(0a200h, CARDINAL(PosX) * 2 + CARDINAL(PosY) * 160);
	ptr^ := ATTRIBUTE;
	IF y >= Base + DLINES THEN
		Movedown( MakePointer( 0a000h, Base160 + 2 * 160 ), MakePointer( 0a000h, Base160 + 160 ), ( DLINES - 2 ) * 160 );
		x := 0; y := Base + DLINES - 1;
		ptr := MakePointer( 0a000h, Base160 + (DLINES - 1) * 160 );
		FOR i := 0 TO 79 DO
			ptr^ := 20h;
			INC( ptr );
			ptr^ := 00h;
			INC( ptr );
		END
	END
	PosX := x;
	PosY := y;
	ptr := MakePointer( 0a200h, CARDINAL(PosX) * 2 + CARDINAL(PosY) * 160 );
	ptr^ := REVERSE;
END SetCur;

PROCEDURE PushScreen;
BEGIN
	OldX := posX;
	OldY := posY;
	Base160 := CARDINAL( Base ) * 160;
	
	SetPos( 0, 25 );
	
(*	キャラクタ領域の待避	*)
	
	ptr := MakePointer( 0a000h, Base160 );
	FOR i := 0 TO HIGH( CharWork ) DO
		CharWork[ i ] := ptr^;
		INC( ptr );
	END;
	
(*	属性領域の待避	*)
	
	ptr := MakePointer( 0a200h, Base160 );
	FOR i := 0 TO HIGH( AttrWork ) DO
		AttrWork[ i ] := ptr^;
		INC( ptr ); INC( ptr );
	END;
	
(*	キャラクタ領域のクリア	*)
	
	ptr := MakePointer( 0a000h, Base160 + 160 );
	FOR i := 0 TO HIGH( AttrWork ) - 80 DO
		ptr^ := 20h;
		INC( ptr );
		ptr^ := 00h;
		INC( ptr );
	END;
	
(*	先頭行, 最終行に罫線を書き込む	*)
	
	ptr := MakePointer( 0a000h, Base160 );
	FOR i := 1 TO 40 DO
		ptr^ := 0ch; INC( ptr );
		ptr^ := 24h; INC( ptr );
		ptr^ := 8ch; INC( ptr );
		ptr^ := 24h; INC( ptr );
	END
	
	ptr := MakePointer( 0a000h, Base160 + DLINES * 160 );
	FOR i := 1 TO 40 DO
		ptr^ := 0ch; INC( ptr );
		ptr^ := 24h; INC( ptr );
		ptr^ := 8ch; INC( ptr );
		ptr^ := 24h; INC( ptr );
	END
	
(*	属性領域のクリア *)
	
	ptr := MakePointer( 0a200h, Base160 );
	FOR i := 0 TO HIGH( AttrWork ) DO
		ptr^ := ATTRIBUTE;
		INC( ptr ); INC( ptr );
	END;
	
	PosX := 0; PosY := Base + 1;
	SetCur( 0, Base + 1 );
END PushScreen;

PROCEDURE PopScreen;
BEGIN
(*	キャラクタ領域の復帰	*)
	
	ptr := MakePointer( 0a000h, Base160 );
	FOR i := 0 TO HIGH( CharWork ) DO
		ptr^ := CharWork[ i ];
		INC( ptr );
	END;
	
(*	属性領域の復帰	*)
	
	ptr := MakePointer( 0a200h, Base160 );
	FOR i := 0 TO HIGH( AttrWork ) DO
		ptr^ := AttrWork[ i ];
		INC( ptr ); INC( ptr );
	END;
	
	SetPos( OldX, OldY );
	
END PopScreen;

PROCEDURE ChangeScreen( pv: PV );
BEGIN
	IF ( pv = up ) AND ( Base = 15 ) THEN
		PopScreen;
		Base := 0;
		PushScreen;
	ELSIF ( pv = down ) AND ( Base = 0 ) THEN
		PopScreen;
		Base := 15;
		PushScreen;
	END
END ChangeScreen;

PROCEDURE GetChar(): CHAR;
BEGIN
	regs.AX := 0;
	Int( 018h, regs );
	RETURN CHR( regs.AL );
END GetChar;

PROCEDURE Write( ch: CHAR );
BEGIN
	ptr := MakePointer( 0a000h, CARDINAL(PosX) * 2 + CARDINAL(PosY) * 160 );
	ptr^ := ch;
	SetCur( PosX + 1, PosY );
END Write;

PROCEDURE WriteString( str: ARRAY OF CHAR );
BEGIN
	i := 0;
	WHILE ( i <= HIGH( str ) ) AND ( str[ i ] <> 0x ) DO
		Write( str[ i ] );
		INC( i );
	END
END WriteString;

PROCEDURE WriteLn;
BEGIN
	SetCur( 0, PosY );
	SetCur( PosX, PosY + 1 );
END WriteLn;

PROCEDURE WSL( str: ARRAY OF CHAR );
BEGIN
	WriteString( str )
	WriteLn;
END WSL;

PROCEDURE WriteStringPos( VAR str: ARRAY OF CHAR; p: CARDINAL );
BEGIN
	WHILE ( p <= HIGH( str ) ) AND ( str[ p ] <> 0x ) DO
		Write( str[ p ] );
		INC( p );
	END
END WriteStringPos;

PROCEDURE GoLeft( i: CARDINAL );
BEGIN
	SetCur( PosX - BYTE( i ), PosY );
END GoLeft;

PROCEDURE GoRight( i: CARDINAL );
BEGIN
	SetCur( PosX + BYTE( i ), PosY );
END GoRight;

PROCEDURE KillRight;
BEGIN
	j := 160 * CARDINAL( PosY );
	FOR i := PosX TO 79 DO
		ptr := MakePointer( 0a000h, 2 * i + j );
		ptr^ := 20h;
		INC( ptr );
		ptr^ := 00h;
	END
END KillRight;

END BIOS.
