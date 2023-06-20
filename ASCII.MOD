
IMPLEMENTATION MODULE Ascii;

FROM BIOS IMPORT
	WriteString, Write, WriteLn;

VAR
	Name: ARRAY [0..1f], [0..2] OF CHAR;

PROCEDURE Hex( i: CARDINAL );
BEGIN
	IF i >= 10 THEN
		Write( CHR( i - 10 + ORD( 'A' ) ) )
	ELSE
		Write( CHR( i + ORD( '0' ) ) )
	END
END Hex;

PROCEDURE AsciiLow;
VAR
	i: CARDINAL;
BEGIN
	FOR i := 0 TO 1fh DO
		Hex( i DIV 16 );
		Hex( i MOD 16 );
		Write( ' ' );
		Write( CHR(i) );
		Write( CHR( i + ORD('@') ) );
		Write( ' ' );
		WriteString( Name[ i ] );
		IF ( i MOD 8 = 7 ) OR ( i = 1fh ) THEN
			WriteLn;
		ELSE
			Write( '|' );
		END
	END
END AsciiLow;

PROCEDURE AsciiHigh;
VAR
	i: CARDINAL;
BEGIN
	FOR i := 20h TO 7fh DO
		Hex( i DIV 16 );
		Hex( i MOD 16 );
		Write( ' ' );
		Write( CHR( i ) );
		IF ( (i - 20h) MOD 16 = 15 ) OR ( i = 7fh ) THEN
			WriteLn;
		ELSE
			Write( '|' );
		END
	END
END AsciiHigh;

BEGIN
	Name[ 00h ] := 'NUL';
	Name[ 01h ] := 'SOH';
	Name[ 02h ] := 'STX';
	Name[ 03h ] := 'ETX';
	Name[ 04h ] := 'EOT';
	Name[ 05h ] := 'ENQ';
	Name[ 06h ] := 'ACK';
	Name[ 07h ] := 'BEL';
	Name[ 08h ] := 'BS ';
	Name[ 09h ] := 'HT ';
	Name[ 0ah ] := 'LF ';
	Name[ 0bh ] := 'VT ';
	Name[ 0ch ] := 'FF ';
	Name[ 0dh ] := 'CR ';
	Name[ 0eh ] := 'SO ';
	Name[ 0fh ] := 'SI ';
	Name[ 10h ] := 'DLE';
	Name[ 11h ] := 'DC1';
	Name[ 12h ] := 'DC2';
	Name[ 13h ] := 'DC3';
	Name[ 14h ] := 'DC4';
	Name[ 15h ] := 'NAK';
	Name[ 16h ] := 'SYN';
	Name[ 17h ] := 'ETB';
	Name[ 18h ] := 'CAN';
	Name[ 19h ] := 'EM ';
	Name[ 1ah ] := 'SUB';
	Name[ 1bh ] := 'ESC';
	Name[ 1ch ] := 'FS ';
	Name[ 1dh ] := 'GS ';
	Name[ 1eh ] := 'RS ';
	Name[ 1fh ] := 'US ';
END Ascii.
