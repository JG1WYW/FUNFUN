
MODULE FUNFUN;

FROM SYSTEM IMPORT
	ADDRESS, ADR TRAP;
FROM LOADER IMPORT
	ProgPrefixAddress;
FROM TakeInt IMPORT
	TakeInt;
FROM IntStub IMPORT
	DisableInterrupts, EnableInterrupts;
FROM Terminal IMPORT
	WriteString, WriteLn;
FROM MSDOS IMPORT
	Int, Registers, SEGMENT;
FROM OtherMSDOS IMPORT
	TermStayRes;
FROM Arg IMPORT
	Argv, Argc;
FROM Hook IMPORT
	CopyHook, BGHook, TriggerFlag;
FROM IR98 IMPORT
	LinkBG, UnlinkBG, NewBG, BGIVA,
	LinkExist, UnlinkExist, EXIST, ETYPE, NewExist, ExistIVA,
	Icall, Free;
FROM Error IMPORT
	Error, ErrorStrategy, Entry;

CONST
	ID = 09611h;						(* ���݊m�F ID *)
	CTYPE = 05h;						(* COPY �L�[ ���荞�݃^�C�v *)

VAR
	Slot: CARDINAL;
	NewCopy, OldCopy: ADDRESS;			(* �V�� COPY IVA �̓��e *)
	CopyIVA[ 0 : CTYPE * 4 ]: ADDRESS;	(* COPY IVA *)
	Cwork: ARRAY [1..512] OF CHAR;		(* COPY ���荞�݃t�b�N�̃��[�N�G���A *)
	regs: Registers;

PROCEDURE Selector( i: CARDINAL ): CARDINAL;
BEGIN
	CASE i OF
		0:
			UnlinkBG;								(* BG IVA ���A *)
			UnlinkExist;							(* Exist IVA ���A *)
			DisableInterrupts;						(* ���荞�݋֎~ *)
			CopyIVA := OldCopy;						(* Copy IVA ���A *)
			EnableInterrupts;						(* ���荞�݋��� *)
			RETURN SEGMENT( ProgPrefixAddress )		(* PSP ��Ԃ� *)
	|	1:
			IF ( NewCopy = CopyIVA ) AND ( NewBG = BGIVA ) AND ( NewExist = ExistIVA ) THEN
				RETURN 1;
			ELSE
				RETURN 0;
			END
	END
	RETURN 0
END Selector;

PROCEDURE WriteFUNFUN( str: ARRAY OF CHAR );
BEGIN
	WriteString( "�ӂ���ӂ���: " );
	WriteString( str );
	WriteLn;
END WriteFUNFUN;

BEGIN
	
(*	�풓�m�F�̊���o��	*)
	
	Entry.AX := ID;
	Int( ETYPE, Entry );
	
	IF Argv[ 1 ]^ = '-r' THEN
		IF Entry.AX = EXIST THEN
			
			Slot := Icall( Entry, 1 );	(* �A�������N�\�� *)
			IF Slot = 0 THEN
				WriteFUNFUN( "�̈����ł��܂���." );
				HALT;
			END
			
			Slot := Icall( Entry, 0 );	(* �e�� IVA �𕜋A����, PSP �𓾂� *)
			Free( Slot );				(* �̈��� *)
			
			WriteFUNFUN( "�̈������܂���." );
		ELSE
			WriteFUNFUN( "�풓���Ă܂���." );
		END
		HALT
	ELSIF Argv[ 1 ]^ = '-h' THEN
		WriteString( "# �풓�֐��d�� �ӂ���ӂ��� V.3.141 Copyright (C) 1993, 1994 by tar." );
		WriteLn;
		WriteString( "#" );
		WriteLn;
		WriteString( "#   Usage: % funfun {-r|-h}  // -r: �풓���, -h: �w���v" );
		WriteLn;
		WriteString( "#" );
		WriteLn;
		WriteString( "# �e�탆�[�e�B���e�B�̒����� COPY �L�[�ŋN�����܂�." );
		WriteLn;
		HALT;
	ELSIF Entry.AX = EXIST THEN
		WriteFUNFUN( "�����풓���Ă܂�." );
		HALT;
	END
	
(*	�g���K�[�ϐ��̏�����	*)
	
	TriggerFlag := FALSE;
	
(*	Link �葱���ɂ�銄�荞�݃t�b�N	*)
	
	LinkExist( ID, Selector, 512 );
	LinkBG( BGHook, 1024 );
	
	Entry.AX := ID;
	Int( ETYPE, Entry );		(* �G���g���[�|�C���g�l�� *)
	
	Entry.DX := CARDINAL( Entry.DX ) - 514;		(* BGHook �ւ̃G���g���[ *)
	
(*	�Â� COPY �L�[�� IVA ���e��Ҕ�	*)
	
	OldCopy := CopyIVA;
	
(*	TakeInt �ɂ�銄�荞�݃t�b�N	*)
	
	Slot := TakeInt( CTYPE, CopyHook, FALSE, ADR( Cwork ), 512 );
	
	NewCopy := CopyIVA;
	
(*	�G���[�g���b�v�E�X�g���e�W�ݒ�	*)
	
	WITH ErrorStrategy DO
		Operation := 0
		Proc := Error;
	END;
	TRAP( ADR( ErrorStrategy ) );
	
(*	Terminate Program but Stay Resident	*)
	
	WriteFUNFUN( "�풓���܂���." );
	
	TermStayRes;
END FUNFUN.
