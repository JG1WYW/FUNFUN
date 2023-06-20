
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
	ID = 09611h;						(* 存在確認 ID *)
	CTYPE = 05h;						(* COPY キー 割り込みタイプ *)

VAR
	Slot: CARDINAL;
	NewCopy, OldCopy: ADDRESS;			(* 新旧 COPY IVA の内容 *)
	CopyIVA[ 0 : CTYPE * 4 ]: ADDRESS;	(* COPY IVA *)
	Cwork: ARRAY [1..512] OF CHAR;		(* COPY 割り込みフックのワークエリア *)
	regs: Registers;

PROCEDURE Selector( i: CARDINAL ): CARDINAL;
BEGIN
	CASE i OF
		0:
			UnlinkBG;								(* BG IVA 復帰 *)
			UnlinkExist;							(* Exist IVA 復帰 *)
			DisableInterrupts;						(* 割り込み禁止 *)
			CopyIVA := OldCopy;						(* Copy IVA 復帰 *)
			EnableInterrupts;						(* 割り込み許可 *)
			RETURN SEGMENT( ProgPrefixAddress )		(* PSP を返す *)
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
	WriteString( "ふぁんふぁん: " );
	WriteString( str );
	WriteLn;
END WriteFUNFUN;

BEGIN
	
(*	常駐確認の割り出し	*)
	
	Entry.AX := ID;
	Int( ETYPE, Entry );
	
	IF Argv[ 1 ]^ = '-r' THEN
		IF Entry.AX = EXIST THEN
			
			Slot := Icall( Entry, 1 );	(* アンリンク可能性 *)
			IF Slot = 0 THEN
				WriteFUNFUN( "領域解放できません." );
				HALT;
			END
			
			Slot := Icall( Entry, 0 );	(* 各種 IVA を復帰して, PSP を得る *)
			Free( Slot );				(* 領域解放 *)
			
			WriteFUNFUN( "領域解放しました." );
		ELSE
			WriteFUNFUN( "常駐してません." );
		END
		HALT
	ELSIF Argv[ 1 ]^ = '-h' THEN
		WriteString( "# 常駐関数電卓 ふぁんふぁん V.3.141 Copyright (C) 1993, 1994 by tar." );
		WriteLn;
		WriteString( "#" );
		WriteLn;
		WriteString( "#   Usage: % funfun {-r|-h}  // -r: 常駐解放, -h: ヘルプ" );
		WriteLn;
		WriteString( "#" );
		WriteLn;
		WriteString( "# 各種ユーティリティの中から COPY キーで起動します." );
		WriteLn;
		HALT;
	ELSIF Entry.AX = EXIST THEN
		WriteFUNFUN( "もう常駐してます." );
		HALT;
	END
	
(*	トリガー変数の初期化	*)
	
	TriggerFlag := FALSE;
	
(*	Link 手続きによる割り込みフック	*)
	
	LinkExist( ID, Selector, 512 );
	LinkBG( BGHook, 1024 );
	
	Entry.AX := ID;
	Int( ETYPE, Entry );		(* エントリーポイント獲得 *)
	
	Entry.DX := CARDINAL( Entry.DX ) - 514;		(* BGHook へのエントリー *)
	
(*	古い COPY キーの IVA 内容を待避	*)
	
	OldCopy := CopyIVA;
	
(*	TakeInt による割り込みフック	*)
	
	Slot := TakeInt( CTYPE, CopyHook, FALSE, ADR( Cwork ), 512 );
	
	NewCopy := CopyIVA;
	
(*	エラートラップ・ストラテジ設定	*)
	
	WITH ErrorStrategy DO
		Operation := 0
		Proc := Error;
	END;
	TRAP( ADR( ErrorStrategy ) );
	
(*	Terminate Program but Stay Resident	*)
	
	WriteFUNFUN( "常駐しました." );
	
	TermStayRes;
END FUNFUN.
