
IMPLEMENTATION MODULE Hook;

FROM Dentaku IMPORT Dentaku;

PROCEDURE CopyHook( VAR regs: Registers; No: CARDINAL );
BEGIN
	TriggerFlag := TRUE;
END CopyHook;

PROCEDURE BGHook;
BEGIN
	IF TriggerFlag THEN			(* Link �葱���̊��荞�݂͍ē����Ȃ� *)
		Dentaku;				(* �f�[�^�ɂ��R�[�h�ɂ����R�ɃA�N�Z�X *)
		TriggerFlag := FALSE;	(* ���̃t���O�ɃZ�}�t�H�͗v��Ȃ����낤 *)
	END
END BGHook;

END Hook.
