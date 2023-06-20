
IMPLEMENTATION MODULE Hook;

FROM Dentaku IMPORT Dentaku;

PROCEDURE CopyHook( VAR regs: Registers; No: CARDINAL );
BEGIN
	TriggerFlag := TRUE;
END CopyHook;

PROCEDURE BGHook;
BEGIN
	IF TriggerFlag THEN			(* Link 手続きの割り込みは再入しない *)
		Dentaku;				(* データにもコードにも自由にアクセス *)
		TriggerFlag := FALSE;	(* このフラグにセマフォは要らないだろう *)
	END
END BGHook;

END Hook.
