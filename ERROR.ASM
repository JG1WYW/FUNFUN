
	LISTS

	MODULE Error

	IMPORT Hook, TriggerFlag, BGHook
	IMPORT BIOS, PopScreen
	IMPORT LexDen, FatalError;

AXOFF	EQU	0
CXOFF	EQU	2
DXOFF	EQU	4
BXOFF	EQU	6
SIOFF	EQU	8
DIOFF	EQU	10
ESOFF	EQU	12
DSOFF	EQU	14
FLAGS	EQU	16

	CSECT
	
	LABEL Error
	
	CALL FatalError
	CALL PopScreen
	
	MOV DS, DSBASE Hook
	MOV BYTE PTR TriggerFlag, 1
	
	MOV DS, DSBASE
	
	MOV BX, OFFSET Entry
	MOV SI, WORD PTR [BX+DSOFF]
	MOV DI, WORD PTR [BX+DXOFF]
	
	SUB DI, 8						; CS, IP, BP, DS
	
	CLI
	MOV SS, SI
	MOV SP, DI
	STI
	
	POP DS
	POP BP
	
	CALL BGHook
	
	RET

	END

