.386

.model flat, stdcall

OPTION  CaseMap:None

; Includes
include C:\masm32_x86\include\windows.inc

include C:\masm32_x86\include\kernel32.inc

include C:\masm32_x86\include\user32.inc


includelib C:\masm32_x86\lib\kernel32.lib

includelib C:\masm32_x86\lib\user32.lib


.data

szClientModuleName db 'client_panorama.dll', 0
szEngineModuleName db 'engine.dll', 0


szNotificationCaption db 'Notification', 0

szErrorClientModule db 'Could not initialize cheat.', 0

szSuccessLoaded		db 'Successfully initialized the cheat.', 0

szSoundESP_Notification db 'SoundESP toggled.', 0

szGlow_Notification db 'Glow toggled.', 0

szDisabled_Notification db 'Disabled Glow & SoundESP.', 0


offset_dwLocalPlayer				dd 00C5E87Ch
offset_iTeamNum						dd 000000F0h
offset_iHealth						dd 000000FCh
offset_EntityList					dd 04C3B384h
offset_vecOrigin					dd 00000134h
offset_dwClientState				dd 00588A74h
offset_dwClientState_MaxPlayer		dd 00000310h
offset_dwGlowObjectManager			dd 0517A668h
offset_dwGlowIndex					dd 0000A320h

bCheatStatus						db 0 

.data?

dwClientBase						dd ?
dwEngineBase						dd ?

dwLocalPlayer						dd ?
dwLocalPlayer_Team					dd ?
dwLocalPlayer_Health				dd ?

dwClientState						dd ?
dwClientState_MaxPlayer				dd ?

dwGlowObjectManager					dd ?

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
	
	; Store eax in dwClientState
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

	; EAX = *(DWORD*)dwClientBase;
	mov eax, dword ptr ds:[ dwClientBase ]

	; EAX += *(DWORD*)offset_dwGlowObjectManager;
	add eax, dword ptr ds:[ offset_dwGlowObjectManager ]

	; EAX = *(DWORD*)EAX;
	mov eax, dword ptr cs:[ eax ]

	cmp eax, 0

	jz Error

	mov dword ptr ds:[ dwGlowObjectManager ], eax


	; Set the return value to 1 ( == true )
	mov eax, 1

	jmp Quit


Error:
	
	; MessageBox( 0, szErrorClientModule, szErrorCaption, 0 )
	invoke MessageBox, 0, offset szErrorClientModule, offset szNotificationCaption, 0

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


	; Initialize fpu stack with default values, no need but just to be 'safe'
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

	; Calculate the root of the sum
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
; Checks if specific keys were pressed and if this was the case bits were modified
; ======================
HandleCheatStatus proc

	push eax

	
	invoke GetAsyncKeyState, VK_F8

	cmp eax, 0

	jnz ToggleSoundESP

	
	invoke GetAsyncKeyState, VK_F9

	cmp eax, 0

	jnz ToggleGlow


	invoke GetAsyncKeyState, VK_F10

	cmp eax, 0

	jnz DisableBoth


	pop eax 

	ret

	
ToggleSoundESP:
	
	xor byte ptr ds:[ bCheatStatus ], 1

	invoke MessageBoxA, 0, offset szSoundESP_Notification, offset szNotificationCaption, 0

	pop eax

	ret

ToggleGlow:

	xor byte ptr ds:[ bCheatStatus ], 2

	invoke MessageBoxA, 0, offset szGlow_Notification, offset szNotificationCaption, 0

	pop eax

	ret

DisableBoth:
	
	mov byte ptr ds:[ bCheatStatus ], 0

	invoke MessageBoxA, 0, offset szDisabled_Notification, offset szNotificationCaption, 0
	
	pop eax

	ret

HandleCheatStatus endp


; ======================
; Description: Returns the health of the player
; Returns: 4 byte signed integer
; ======================
GetHealthFromPlayer proc

	mov eax, dword ptr ds:[ dwLocalPlayer_Health ]

	mov eax, [ eax ]

	ret

GetHealthFromPlayer endp


; ==================
; Returns the glow index from a entity as a 4 byte signed integer
; ==================
GetGlowIndexFromEntity proc dwEntity:dword
	
	; EAX = *(DWORD*)( EBP + $dwEntity );
	mov eax, dwEntity

	; EAX += *(DWORD*)offset_dwGlowIndex;
	add eax, dword ptr ds:[ offset_dwGlowIndex ]

	; EAX = *(DWORD*)EAX;
	mov eax, dword ptr cs:[ eax ]

	ret 4

GetGlowIndexFromEntity endp

; ==================
; 'Registers' a glow object with given index of the array( glowobjectmanager )
; ==================
GlowEntity proc dwIndex:dword

	local dwTemp : dword ; A local variable which will hold temporary values for the fpu usage

	push eax

	push edx

	push ebx


	mov edx, dword ptr ds:[ dwGlowObjectManager ] 

	mov ebx, dword ptr ss:[ dwIndex ]

	imul ebx, 56 

	lea eax, dword ptr cs:[ edx + ebx ] ; EAX contains now dwGlowObjectManager + dwIndex * 56

	
	add eax, 4 ; 'Points' to m_flRed

	finit ; Initialize fpu stack

	mov dwTemp, 1 
	fild dword ptr ss:[ dwTemp ] 
	fstp real4 ptr [ eax ] ; GlowObject->m_flRed = (float)1;

	add eax, 4 ; 'Points' to m_flGreen
	mov dwTemp, 0
	fild dword ptr ss:[ dwTemp ]
	fstp real4 ptr [ eax ] ; GlowObject->m_flGreen = (float)0;

	add eax, 4 ; 'Points' to m_flBlue
	fild dword ptr ss:[ dwTemp ]
	fstp real4 ptr [ eax ] ; GlowObject->m_flBlue = (float)0;

	add eax, 4 ; 'Points' to m_flAlpha
	mov dwTemp, 1
	fild dword ptr ss:[ dwTemp ] 
	fstp real4 ptr [ eax ] ; GlowObject->m_flAlpha = (float)1;

	add eax, 20 ; Skip some variables
	mov byte ptr [ eax ], 1 ; Set m_bRenderOccluded to 1
	
	inc eax
	mov byte ptr [ eax ], 0 ; Set m_bRenderUnoccluded to 0

	pop ebx

	pop edx

	pop eax

	ret 4

GlowEntity endp



; ======================
; |		Entrypoint     |
; ======================
main proc hInstDLL:dword, fdwReason:dword, lpReserved:dword

Setup:
	
	call InitializeCheat

	cmp eax, 0

	jz RetrySetup

	invoke MessageBoxA, 0, offset szSuccessLoaded, offset szNotificationCaption, 0

Preroutine:

	call HandleCheatStatus

	invoke Sleep, 1

Think:

	movsx eax, byte ptr ds:[ bCheatStatus ]

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

	jz SkipEntity

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

	push esi

	movsx esi, byte ptr ds:[ bCheatStatus ]

	cmp esi, 1

	pop esi

	jz DoSoundESP

	jg DoGlow

	jl SkipEntity

	jmp SkipEntity ; Really strange, vs doesn't like jl
	
DoGlow:
	push edx
	call GetGlowIndexFromEntity

	push eax
	cmp eax, 0
	pop eax

	jle InvalidGlowIndex

	push eax
	call GlowEntity

	jmp SkipEntity

DoSoundESP:

	invoke Beep, 1337h, 32h

	jmp SkipEntity


InvalidGlowIndex:

	invoke Sleep, 1

	jmp SkipEntity


ExitEntityLoopAndPrestart:
	
	pop ebx

	pop edx

	pop esi

	pop edi

	jmp PreStartAgain
	

SkipEntity:

	inc ebx

	jmp EntityLoop


PreStartAgain:

	invoke Sleep, 1

	jmp Preroutine

RetrySetup:

	invoke Sleep, 1

	jmp Setup

main endp

end main
