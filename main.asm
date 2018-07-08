.386

.model flat, stdcall

OPTION  CaseMap:None

; Includes
 include C:\masm32\include\windows.inc

 include C:\masm32\include\kernel32.inc

 include C:\masm32\include\user32.inc


 includelib C:\masm32\lib\kernel32.lib

 includelib C:\masm32\lib\user32.lib


.data

szClientModuleName db 'client.dll', 0
szEngineModuleName db 'engine.dll', 0

szErrorCaption db '[ERROR]', 0
szErrorClientModule db 'Could not initialize cheat', 0

szStatusEnabled db 'Cheat is enabled!', 0
szStatusDisabled db 'Cheat is disabled!', 0

offset_dwLocalPlayer				dd 00AB5D3Ch
offset_iTeamNum						dd 000000F0h
offset_iHealth						dd 000000FCh
offset_EntityList					dd 04A913B4h
offset_vecOrigin					dd 00000134h
offset_dwClientState				dd 00586A74h
offset_dwClientState_MaxPlayer		dd 00000310h

dwCheatStatus						dd 00000000h

.data?

dwClientBase			dd ?
dwEngineBase			dd ?

dwLocalPlayer			dd ?
dwLocalPlayer_Team		dd ?
dwLocalPlayer_Health	dd ?

dwClientState			dd ?
dwClientState_MaxPlayer	dd ?
.code

; ======================
; Description: Initializes some important values for the further usage, like dwClientBase, dwLocalPlayer etc
; Returns: 0 if it fails and 1 if the initialization process was successful
; ======================
InitializeCheat proc

	; Get image base from client.dll
	push offset szClientModuleName
	call GetModuleHandle

	cmp eax, 0

	jz Error

	; Store image base in dwClientBase
	mov dword ptr ds:[ dwClientBase ], eax

	; Get image base from engine.dll
	push offset szEngineModuleName
	call GetModuleHandle

	cmp eax, 0

	jz Error

	; Store image base in dwEngineBase
	mov dword ptr ds:[ dwEngineBase ], eax

	; Add the offset of clientstate on eax
	add eax, dword ptr ds:[ offset_dwClientState ]

	; Dereference the address and store it in eax
	mov eax, dword ptr cs:[ eax ]

	cmp eax, 0

	jz Error
	
	; Store eax in dwClientBase
	mov dword ptr ds:[ dwClientState ], eax

	; Add the offset for clientstate_MaxPlayer on eax
	add eax, dword ptr ds:[ offset_dwClientState_MaxPlayer ]

	; Move the relative address of it in dwClientState_MaxPlayer
	mov dword ptr ds:[ dwClientState_MaxPlayer ], eax

	; Move clientbase in eax
	mov eax, dword ptr ds:[ dwClientBase ]

	; Add the offset of the localplayer on the image base
	add eax, dword ptr ds:[ offset_dwLocalPlayer ]

	; Move the dereferenced value into eax
	mov eax, [ eax ]

	cmp eax, 0

	jz Error
	
	; Move the localplayer address in dwLocalPlayer
	mov dword ptr ds:[ dwLocalPlayer ], eax
	
	; Add the team offset on the localplayer
	add eax, dword ptr ds:[ offset_iTeamNum ]

	; Move the dereferenced value into eax
	mov eax, [ eax ]

	cmp eax, 0

	jz Error

	; Move the team number of the localplayer into dwLocalPlayer_Team
	mov dword ptr ds:[ dwLocalPlayer_Team ], eax

	; Move localplayer in eax
	mov eax, dword ptr ds:[ dwLocalPlayer ]

	; Add the health offset on eax
	add eax, dword ptr ds:[ offset_iHealth ]

	; I don't check the address here for invalidation because LocalPlayer is valid and the offset should be too
	; It is not perfect, I know.

	; Move the 'relative' address in eax
	mov dword ptr ds:[ dwLocalPlayer_Health ], eax


	; Set the return value to 1 ( == true )
	mov eax, 1

	jmp Quit


Error:
	
	; MessageBox( 0, szErrorClientModule, szErrorCaption, 0 )
	invoke MessageBox, 0, offset szErrorClientModule, offset szErrorCaption, 0

	; Sleep( 5000 )
	invoke Sleep, 5000

	; Set the return value to 0 ( == false )
	mov eax, 0

	jmp Quit

Quit:

	; Pop return address from stack and continue execution
	ret

InitializeCheat endp


; ======================
; Description: Returns a handle to an entity by the given index
; Returns: 4 byte signed address ( == entity handle )
; ======================
GetEntityByIndex proc dwIndex:dword
	
	; Temporary register which contains the address of clientbase + entitylist
	push edx

	; Move dwClientBase in edx
	mov edx, dword ptr ds:[ dwClientBase ]

	; Add the offset for the entitylist on edx
	add edx, dword ptr ds:[ offset_EntityList ]

	; Temporary register which contains the index multiplied with the size of an entry
	push ebx

	; Move the index, which is on the stack, in ebx
	mov ebx, dword ptr ss:[ dwIndex ] ; I want to write ebp + 8 but I can't ignore the vs warning :P

	; Multiply with 10h/ 16 to get the correct size
	; I choose signed multiply here because I want only one instruction, for mul I need to prepare two gpr and I didn't have the option to mutliply with a immediate value
	imul ebx, 10h

	; Load the address into eax
	lea eax, dword ptr cs:[ edx + ebx ]

	; Dereference the address of the entity, if the index is invalid this might cause a crash
	mov eax, dword ptr cs:[ eax ]

	; Pop both registers from the stack 
	pop ebx

	pop edx

	; Pop return address from stack and 4 bytes for the pushed parameter and continue execution at return address
	ret 4

GetEntityByIndex endp

; ======================
; Description: Returns the health of a entity
; Returns: 4 byte signed int ( == entity health )
; ======================
GetEntityHealth proc dwEntity:dword
	
	; Move the entity in eax
	mov eax, dword ptr ss:[ dwEntity ]
	
	; Add the health offset to the entity
	add eax, dword ptr ds:[ offset_iHealth ]

	; Dereference the address
	mov eax, dword ptr cs:[ eax ]

	ret 4
	
GetEntityHealth endp

; ======================
; Description: Returns the team of a entity
; Returns: 4 byte signed int ( == entity team )
; ======================
GetEntityTeam proc dwEntity:dword

	mov eax, dword ptr ss:[ dwEntity ]

	add eax, dword ptr ds:[ offset_iTeamNum ]

	mov eax, dword ptr cs:[ eax ]

	ret

GetEntityTeam endp

; ======================
; Description: Returns the address of the position for an entity 
; Returns: 4 byte address
; ======================
GetPositionFromEntity proc dwEntity:dword
	
	; Move entity in eax register
	mov eax, dword ptr ss:[ dwEntity ]

	; Add vecOrigin offset to eax
	add eax, dword ptr ds:[ offset_vecOrigin ]

	; Pop 4 bytes from stack and the return address for continue executing
	ret 4

GetPositionFromEntity endp

; ======================
; Description: Returns the address for the position from the Player
; Returns: 4 byte address
; ======================
GetPositionFromPlayer proc
	
	; Move localplayer in eax
	mov eax, dword ptr ds:[ dwLocalPlayer ]

	; Add the vecOrigin offset on eax
	add eax, dword ptr ds:[ offset_vecOrigin ]

	ret

GetPositionFromPlayer endp

; ======================
; Description: Returns the team of the player
; Returns: 4 byte signed int ( == player team )
; ======================
GetTeamFromPlayer proc

	mov eax, dword ptr ds:[ dwLocalPlayer ]

	add eax, dword ptr ds:[ offset_iTeamNum ]

	mov eax, [ eax ]

	ret

GetTeamFromPlayer endp

; ======================
; Description: Returns the distance from an entity to the player, if it fails the return value is -1
; Returns: 4 byte signed int ( == rounded distance )
; ======================
GetDistanceToEntity proc dwEntity:dword
	
	; Masm love, I could also do sub esp, 4 for allocating space
	local dwDistance : dword

	; Loading entity from the stack[ ebp + 8 ] into eax
	mov eax, dword ptr ss:[ dwEntity ]

	; Pushing entity and getting the position
	push eax
	call GetPositionFromEntity

	; check if the referenced address is invalid
	cmp eax, 0

	; if so jump to fail label
	jz Fail

	; Register which will hold the entity position address
	push ebx

	; move the referenced address in ebx
	mov ebx, eax

	; Get the position from the player
	call GetPositionFromPlayer

	; check if the referenced address is invalid
	cmp eax, 0

	; yeah.. jump to fail label if it is invalid
	jz Fail


	; Initialize fpu stuck with default values, no need but just to be 'safe'
	finit

	; Load the x coordinate from the entity and the player with pointer size as 32 bit single precision floating point value
	fld real4 ptr cs:[ ebx ]

	fld real4 ptr cs:[ eax ]

	; Subtract both and pop first element on stack
	fsubp

	; Multiply the first element with itself so just squared it to be positive
	fmul st( 0 ), st( 0 )


	; Load the y coordinate from the entity and the player with pointer size as 32 bit single precision floating point value
	fld real4 ptr cs:[ ebx + 4 ]

	fld real4 ptr cs:[ eax + 4 ]

	fsubp

	fmul st( 0 ), st( 0 )


	;Load the z coordinate from the entity and the player with pointer size as 32 bit single precision floating point value
	fld real4 ptr cs:[ ebx + 8 ]

	fld real4 ptr cs:[ eax + 8 ]

	fsubp

	fmul st( 0 ), st( 0 )

	; Add the first two elements together and pop first element from the stack
	faddp

	; add the first element with the second element and pop the first element from the stack
	faddp

	; Square the first element
	fsqrt

	; Store the first element as a integer with pointer size 4 byte in the local variable
	fistp dword ptr ss:[ dwDistance ]

	; Pop the pushed register
	pop ebx

	; Move the distance into eax
	mov eax, dword ptr ss:[ dwDistance ]

	; Pop 4 bytes because of the paramter and pop the return address and jump to it
	ret 4


Fail:
	
	; Move -1 into eax because no distance can be negative
	mov eax, -1

	; Pop 4 bytes because of the paramter and pop the return address and jump to it
	ret 4


GetDistanceToEntity endp

; ======================
; Description: Returns the number of connected clients
; Returns: 4 byte signed integer
; ======================
GetMaxClients proc

	mov eax, dword ptr ds:[ dwClientState_MaxPlayer ]

	mov eax, [ eax ]

	ret

GetMaxClients endp

; ======================
; Description: Set the variable dwCheatStatus to 0 or 1, depends on it last number
; Returns: n o t h i n g..oh
; ======================
ToggleCheatStatus proc

	push eax

	mov eax, dword ptr ds:[ dwCheatStatus ]

	cmp eax, 0

	pop eax

	jz Enable

	jg Disable

Enable:
	
	mov dword ptr ds:[ dwCheatStatus ], 1

	invoke MessageBox, 0, 0, offset szStatusEnabled, 0

	ret

Disable:
	
	mov dword ptr ds:[ dwCheatStatus ], 0

	invoke MessageBox, 0, 0, offset szStatusDisabled, 0

	ret

ToggleCheatStatus endp


; ======================
; Description: Returns the health of the player
; Returns: 4 byte signed integer
; ======================
GetHealthFromPlayer proc

	mov eax, dword ptr ds:[ dwLocalPlayer_Health ]

	mov eax, [ eax ]

	ret

GetHealthFromPlayer endp


; ======================
; |		Entrypoint     |
; ======================
main proc hInstDLL:dword, fdwReason:dword, lpReserved:dword

Setup:
	
	call InitializeCheat

	cmp eax, 0

	jz RetrySetup


Preroutine:

	; Actually I don't like invoke but it is kinda smooth... checking if end key is pressed
	invoke GetAsyncKeyState, VK_END

	cmp eax, 0

	jnz ToggleStatus


Think:

	mov eax, dword ptr ds:[ dwCheatStatus ]

	cmp eax, 0

	jz PreStartAgain

	call GetHealthFromPlayer

	cmp eax, 0

	jle PreStartAgain

	call GetMaxClients

	cmp eax, 0

	jle PreStartAgain

	push edi

	mov edi, eax

	call GetTeamFromPlayer

	cmp eax, 0

	jle PreStartAgain

	push esi

	mov esi, eax

	push edx

	push ebx

	xor ebx, ebx

EntityLoop:

	cmp ebx, edi

	jz ExitEntityLoopAndPrestart

	push ebx
	call GetEntityByIndex

	cmp eax, 0

	jle SkipEntity

	mov edx, eax

	push eax
	call GetEntityTeam

	cmp eax, 0

	jle SkipEntity

	cmp eax, esi

	jz SkipEntity

	push edx
	call GetDistanceToEntity

	; Substract 600 from eax, 600 is our distance at which the soundesp should *beep*
	cmp eax, 600

	jg SkipEntity

	; much leet, much wow
	invoke Beep, 1337h, 32h

	jmp SkipEntity


ExitEntityLoopAndPrestart:
	
	pop ebx

	pop edx

	pop esi

	pop edi

	jmp PreStartAgain
	

SkipEntity:
	
	invoke GetAsyncKeyState, VK_END

	cmp eax, 0

	jnz ExitEntityLoopAndToggleStatus

	inc ebx

	jmp EntityLoop


ExitEntityLoopAndToggleStatus:

	pop ebx

	pop edx

	pop esi

	pop edi

	call ToggleCheatStatus

	jmp PreStartAgain

ToggleStatus:
	
	invoke Sleep, 1

	call ToggleCheatStatus

	jmp Preroutine

PreStartAgain:

	invoke Sleep, 1

	jmp Preroutine

RetrySetup:

	invoke Sleep, 1

	jmp Setup

main endp

end main
