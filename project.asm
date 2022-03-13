; Nev: Mátis Krisztián
; Azonosito: mkim2052
; Csoport: 513

; Feladat: Projekt - Kézzel írott számjegyek felismerése neurális hálóval

%include 'io.inc'
%include 'util.inc'
%include 'gfx.inc'

%define WIDTH  1100					;Ablak meretei
%define HEIGHT 756
%define START_BUTTON_X 825			;Szamfelismeres elindito gombjanak kiindulo koordinatai
%define START_BUTTON_Y 650
%define RESET_BUTTON_X 975			;Rajzfelulet torleset biztosito gomb kiindulo koordinatai
%define RESET_BUTTON_Y 650
%define BUTTON_HEIGHT 50			;Gombok meretei
%define BUTTON_WIDTH 60
%define THICC 13					;Rajzolt negyzet vastagsaga

global main

section .text

;Be: EBX - kep, ECX - kep merete, DL - padding vastagsag, DH - retegek szama
;Ki: EBX
Padding:
	push 	eax
	push 	esi
	push 	edi
	
	mov 	edi, padded
	mov 	esi, ecx
	push 	edx
	and 	edx, 0xFF
	add 	esi, edx 		;ESI - top es bottom padding 0-k szama
	add 	esi, edx
	imul 	esi, edx
	pop 	edx
	xor 	eax, eax
	
	.layer:
		cmp 	al, dh
		je 		.end
		inc 	eax
		push 	eax
		xor 	eax, eax
		
		.top:
			cmp 	eax, esi
			je 		.middle
			inc 	eax
			mov 	dword[edi], 0
			add 	edi, 4
			jmp 	.top
			
		.middle:
			xor 	esi, esi
			
			.left:
				cmp 	esi, ecx
				je 		.bottom
				
				inc 	esi
				xor 	eax, eax
			
				.left_row:
					cmp 	al, dl
					je 		.image
					mov 	dword[edi], 0
					inc 	eax
					add 	edi, 4
					jmp 	.left_row
					
				.image:
					xor 	eax, eax
					
					.img_row:
						cmp 	eax, ecx
						je 		.right
						push 	eax
						mov 	eax, dword[ebx]
						mov 	[edi], eax
						add 	ebx, 4
						add 	edi, 4
						pop 	eax
						inc 	eax
						jmp 	.img_row
					
				.right:
					xor 	eax, eax
					
					.right_row:
						cmp 	al, dl
						je 		.left
						mov 	dword[edi], 0
						inc 	eax
						add 	edi, 4
						jmp 	.right_row
					
		.bottom:
			xor 	eax, eax
			
			.bottom_row:
				cmp 	eax, esi
				je 		.next_layer
				inc 	eax
				mov 	dword[edi], 0
				add 	edi, 4
				jmp 	.bottom_row
				
	.next_layer:
		pop 	eax
		jmp 	.layer
				
	.end:
		pop 	edi
		pop 	esi
		pop 	eax
		mov 	ebx, padded
		
	ret




;Be: EBX - in params, CL - in channels, CH - out channels, EDX - kep merete; + bin paramss
;Ki: EDI
Conv2d:
	push 	eax
	push 	ebx
	push 	edx
	push 	esi
	push 	edi
	
	sub 	edx, 2			;3*3-as filter a kepmeret-2 helytol indulhat legfeljebb 
	xor 	eax, eax
	mov 	esi, bin_paramss
	
	.out_loop:				;ahany kimeneti layer
		cmp 	al, ch
		je 		.bias
		inc 	eax
		push 	eax
		push 	ebx						;EBX az in params elejen van - a tobbszori filterezes miatt mentjuk ki
		push 	esi
		xor 	eax, eax
		
		.y_loop:					;Ahany sor
			cmp 	eax, edx
			je 		.y_end
			inc 	eax
			push 	eax
			xor 	eax, eax
			
			.x_loop:				;Ahany oszlop
				cmp 	eax, edx
				je 		.x_end
				inc 	eax
				push 	eax
				xor 	eax, eax
				xorps 	xmm0, xmm0
				push 	ebx				;EBX az elso layeren van - a tobbszoros vastagsag/layer miatt mentjuk ki
				push 	esi
				
				.in_loop:					;Ahany bemeneti reteg
					cmp 	al, cl
					je 		.layer_end
					inc 	eax
					
					push 	edx
					add 	edx, 2
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx]				;3*3 resz bejarasa - hardcode, no more loops
					mulss 	xmm1, [esi]
					addss 	xmm0, xmm1

					xorps 	xmm1, xmm1					
					movss 	xmm1, [ebx+4]
					mulss 	xmm1, [esi+4]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+8]
					mulss 	xmm1, [esi+8]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+edx*4]
					mulss 	xmm1, [esi+12]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+edx*4+4]
					mulss 	xmm1, [esi+16]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+edx*4+8]
					mulss 	xmm1, [esi+20]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+8*edx]
					mulss 	xmm1, [esi+24]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+8*edx+4]
					mulss 	xmm1, [esi+28]
					addss 	xmm0, xmm1
					
					xorps 	xmm1, xmm1
					movss 	xmm1, [ebx+8*edx+8]
					mulss 	xmm1, [esi+32]
					addss 	xmm0, xmm1
					
					imul 	edx, edx
					imul 	edx, 4
					
					add 	ebx, edx
					pop 	edx
					add 	esi, 36
					jmp 	.in_loop
					
				.layer_end:
					pop 	esi
					pop 	ebx
					pop 	eax
					movss 	[edi], xmm0
					add 	edi, 4
					
					add 	ebx, 4
					jmp 	.x_loop
					
			.x_end:
				pop 	eax
				add 	ebx, 8
				jmp 	.y_loop
				
		.y_end:
			pop 	esi
			push 	ecx
			and 	ecx, 0xFF
			imul 	ecx, 36		
			add 	esi, ecx
			pop 	ecx
			pop 	ebx
			pop 	eax
			jmp 	.out_loop
			
	.bias:
		pop 	edi
		mov 	eax, edi
		
		push 	edi
		xor		eax, eax
		imul 	edx, edx
		
		.bias_loop:
			cmp 	al, ch
			je 		.end
			inc 	eax
			movss 	xmm0, [esi]				;egyetlen bias ertek
			add 	esi, 4
			xor 	ebx, ebx
			
			.layer_bias:
				cmp 	ebx, edx
				je 		.layer_bias_end
				inc 	ebx
				movss 	xmm1, [edi]
				addss 	xmm1, xmm0
				movss 	[edi], xmm1
				add 	edi, 4
				jmp 	.layer_bias
				
			.layer_bias_end:
				jmp 	.bias_loop
			
	.end:
		pop 	edi
		pop 	esi
		pop 	edx
		pop 	ebx
		pop 	eax
		
	ret
	
	
	
	
;Be: EBX - bemeneti parameterek/kep, ECX - parameterek szama
;Ki: EBX
ReLU:
	push 	eax
	push 	ebx
	
	xor 	eax, eax
	xorps 	xmm0, xmm0
	
	.loop:
		cmp 	eax, ecx
		je 		.vege
		comiss 	xmm0, [ebx]
		jb 		.skip
		mov 	dword[ebx], 0
	
	.skip:
		add 	ebx, 4
		inc 	eax
		jmp 	.loop
	
	.vege:
		pop 	ebx
		pop 	eax
		
	ret
	
	
;Be: EBX - bemeneti parameterek/kep, ECX - retegek szama, EDX - kep merete
;Ki: EDI
MaxPool2d:
	push 	eax
	push 	ebx
	push 	edi
	
	xor 	eax, eax
	
	.layer_loop:
		cmp 	eax, ecx
		je 		.vege
		inc 	eax
		push 	eax
		xor 	eax, eax
		
		.y_loop:
			cmp 	eax, edx
			je		.y_end
			add 	eax, 2
			push 	eax
			xor 	eax, eax
			
			.x_loop:
				cmp 	eax, edx
				je 		.x_end
				add 	eax, 2
				
				movss 	xmm0, [ebx]
				comiss 	xmm0, [ebx+4]
				jae 	.next1
				movss 	xmm0, [ebx+4]
				
				.next1:
				comiss 	xmm0, [ebx+edx*4]
				jae 	.next2
				movss 	xmm0, [ebx+edx*4]
				
				.next2:
				comiss 	xmm0, [ebx+edx*4+4]
				jae 	.next3
				movss 	xmm0, [ebx+edx*4+4]
				
				.next3:
				movss 	[edi], xmm0
				add 	edi, 4
				add 	ebx, 8
				jmp 	.x_loop
				
			.x_end:
				push 	edx
				imul 	edx, 4
				add 	ebx, edx
				pop 	edx
				pop 	eax
				jmp 	.y_loop
		
		.y_end:
			pop 	eax
			jmp 	.layer_loop
			
	.vege:
		pop 	edi
		pop 	ebx
		pop 	eax
		
	ret



;Be: EBX - in params, ECX - in features, EDX - out features
;Ki: EDI 
Linear:
	push 	eax
	push 	ebx
	push 	esi
	push 	edi
	
	push 	edi
	xor 	eax, eax
	mov 	esi, bin_paramss
	
	.out_loop:
		cmp 	eax, edx
		je 		.bias
		inc 	eax
		push 	ebx
		push 	eax
		xor 	eax, eax
		xorps 	xmm0, xmm0
		
		.in_loop:
			cmp 	eax, ecx
			je 		.in_end
			inc 	eax
			
			xorps	xmm1, xmm1
			movss 	xmm1, [ebx]
			add 	ebx, 4
			xorps 	xmm2, xmm2
			movss 	xmm2, [esi]
			add 	esi, 4
			mulss 	xmm1, xmm2
			addss 	xmm0, xmm1
			jmp 	.in_loop
			
		.in_end:
			movss 	[edi], xmm0
			add 	edi, 4
			mov 	eax, esi
			pop 	eax
			pop 	ebx
			jmp 	.out_loop
			
	.bias:
		pop 	edi
		xor 	eax, eax
		xorps 	xmm0, xmm0
		
		.bias_loop:
			cmp 	eax, edx
			je 		.vege
			inc 	eax
			movss 	xmm0, [esi]
			add 	esi, 4
			addss 	xmm0, dword[edi]
			movss 	[edi], xmm0
			add 	edi, 4
			jmp 	.bias_loop
			
	.vege:
		pop 	edi
		pop 	esi
		pop 	ebx
		pop 	eax
		
	ret

	
	

;Be: in_params tombbe kimentett 28x28 kep
;Ki: EAX - felismert szamjegy
;Az atmeretezett kep feldolgozasa a halo szerkezete alapjan
NeuralNetwork:
	push 	ebx
	push 	ecx
	push 	edx
	push 	esi
	push 	edi					
	
	mov 	edx, 28				;EDX - kep/retegek merete
	mov 	esi, sorrend
	mov 	eax, bin_file
	mov 	ebx, 0
	call 	fio_open			;EAX - bin. file handle
	
	mov 	ebx, in_params			;EBX - Bemeneti tomb
	mov 	edi, out_params			;EDI - Kimeneti tomb
	
	.szerkezet:
		push 	eax
		lodsd
		cmp 	eax, 1
		je 		.conv
		cmp 	eax, 2
		je 		.relu
		cmp 	eax, 3
		je 		.maxpool
		cmp 	eax, 4
		je 		.linear
		jmp 	.softmax
		
	.conv:
		pop 	eax
		push 	ebx
		push 	edx
		push 	eax
		
		mov 	ecx, [esi]
		imul 	ecx, [esi+4]
		imul 	ecx, 36
		mov 	ebx, [esi+4]
		imul 	ebx, 4
		add 	ecx, ebx
		mov 	ebx, bin_paramss
		pop 	eax
		call 	fio_read
		pop 	edx
		pop 	ebx
		
		push 	edx
		mov 	ecx, edx				;ECX - kep merete
		mov 	edx, dword[esi]			;EDX (DL) - in channels / retegek szama
		shl 	edx, 8
		add 	edx, dword[esi+8]		;DH - retegek szama, DL - padding vastagsag
		
		cmp 	dl, 0
		je 		.no_padding
		call 	Padding
		
		.no_padding:
		pop 	edx
		add 	edx, [esi+8]			;Kepmeret novelese 2*padding-el
		add 	edx, [esi+8]
		
		mov 	ecx, dword[esi+4]
		shl 	ecx, 8
		add 	ecx, dword[esi]			;CL - in channels, CH - out channels
		add 	esi, 12

		call 	Conv2d
		
		sub 	edx, 2			;Konvolucio utan a kepmeret csokken
		push 	eax
		
		mov 	eax, ebx			;Be es kimeneti tombok csereje
		mov 	ebx, edi
		mov 	edi, eax
		pop 	eax
		
		jmp 	.szerkezet
		
		
	.relu:
		mov 	eax, [esi-20]
		cmp 	eax, 4
		je 		.lin
		
		mov 	ecx, edx					;Conv2d parameterei alapjan kiszamoljuk a feldolgozando float-ok szamat (Ha fc van elotte, skippeli a reteg szamolast)
		imul 	ecx, edx
		imul 	ecx, [esi-12]
		jmp 	.call_relu
		
		.lin:
		mov 	ecx, [esi-16]
		
		.call_relu:
		call 	ReLU
		
		pop 	eax
		jmp 	.szerkezet
		
	.maxpool:
		mov 	ecx, dword[esi-16]
		add 	esi, 20
		
		call 	MaxPool2d

		mov 	eax, edx
		push 	ebx
		mov 	ebx, 2
		cdq
		idiv 	ebx				;MaxPool utan felezzuk a kep meretet (kernel size=2, stride=2, padding=0 fixed)
		mov 	edx, eax
		
		pop 	ebx
		mov 	eax, ebx		;Be es kimeneti tombok csereje
		mov 	ebx, edi
		mov 	edi, eax
		pop 	eax
		
		jmp 	.szerkezet
		
	.linear:
		pop 	eax
		push 	ebx
		push 	edx
		
		mov 	ecx, dword[esi]
		imul 	ecx, dword[esi+4]
		add 	ecx, dword[esi+4]
		imul 	ecx, 4
		mov 	ebx, bin_paramss
		call 	fio_read
		pop 	edx
		pop 	ebx

		push 	eax
		
		mov 	ecx, [esi]
		add 	esi, 4
		push 	edx
		mov 	edx, [esi]
		add 	esi, 8 					;bias = True fixed
		
		call 	Linear

		pop 	edx
		mov 	eax, ebx			;Be es kimeneti tombok csereje
		mov 	ebx, edi
		mov 	edi, eax
		
		pop 	eax
		
		jmp 	.szerkezet
		
	.softmax:
		pop 	eax
		
		xor 	ecx, ecx
		push 	ebx					;10 kimenet a linear-bol
		xorps 	xmm1, xmm1			;nevezo - exp tagok osszege
		
		.exp:
			cmp 	ecx, 10
			je 		.max
			movss 	xmm0, [ebx]
			call	exp_ss

			inc 	ecx
			movss 	[ebx], xmm0
			add 	ebx, 4
			addss 	xmm1, xmm0
			jmp 	.exp
		
		.max:
			pop 	ebx
			xor 	ecx, ecx
			xorps 	xmm2, xmm2
			
			.div:
				cmp 	ecx, 10
				je 		.end
				movss 	xmm0, [ebx]
				divss 	xmm0, xmm1
				movss 	[ebx], xmm0			;debugging - lassam mennyi az osszes szamjegy szazalekos valoszinusege
				comiss 	xmm2, xmm0
				ja 		.skip
				mov 	eax, ecx
				
				movss 	xmm2, xmm0
				
				.skip:
				inc 	ecx
				add 	ebx, 4
				jmp 	.div
				
	.end:
		pop 	edi
		pop 	esi
		pop 	edx
		pop 	ecx
		pop 	ebx
	
	ret



;Be: EAX - pointer az adott pixelre
;Ki: ESI, EDI - X, Y koordinatak
;Egy adott pixel koordinatainak meghatarozasa a memoriacime alapjan
pixelpos:
	push 	eax
	push 	ebx
	push 	edx
	
	mov 	ebx, eax
	call 	gfx_map
	sub 	ebx, eax
	
	mov 	eax, ebx
	mov 	ebx, WIDTH*4
	cdq
	idiv 	ebx
	mov 	edi, eax
	mov 	eax, edx
	mov 	ebx, 4
	cdq
	idiv	ebx
	mov 	esi, eax
	
	
	pop 	edx
	pop 	ebx
	pop 	eax
	
	ret
	

;Be: EAX - pointer az adott pixelre
;Osszefuggo komponensek keresese backtrackinggel
backtrack:
	push 	eax
	push 	ebx
	push 	esi
	push 	edi
	
	mov 	ebx, [eax]
	cmp 	ebx, 0xFFFFFF
	jne 	.vege
	
	call 	pixelpos				;Elmentjuk a komponensek szelsoertek koordinatait, azaz a komponens legfelso es legalso Y koordinatait, illetve legbaloldalibb es legjobboldalibb X koordinatait
	
	cmp 	esi, dword[left]
	jg 		.next1
	mov 	dword[left], esi
	
	.next1:
		cmp 	esi, dword[right]
		jl 		.next2
		mov 	dword[right], esi
	
	.next2:
		cmp 	edi, dword[top]
		jg 		.next3
		mov 	dword[top], edi
		
	.next3:
		cmp 	edi, dword[bottom]
		jl 		.bt
		mov 	dword[bottom], edi
	
	.bt:
	mov 	dword[eax], 0x00FF0000
	sub 	eax, 4
	call 	backtrack
	add 	eax, 8
	call 	backtrack
	sub 	eax, WIDTH*4 + 4
	call 	backtrack
	add 	eax, WIDTH*8
	call 	backtrack
	
	.vege:
		pop 	edi
		pop 	esi
		pop 	ebx
		pop 	eax
		
	ret


;Be: Valtozokba mentett szelsoertek koordinatak
;A backtracking soran atszinezett pixelek visszaallitasa feherre
back_to_white:
	push 	eax
	push 	ebx
	push 	ecx
	push 	edx
	
	call 	gfx_map
	xor 	ecx, ecx
	
.y_loop:
	cmp 	ecx, HEIGHT
	jge 	.vege
	
	xor 	edx, edx
	
.x_loop:
	cmp 	edx, HEIGHT
	je 		.x_end
	
	cmp 	dword[eax], 0x00FF0000
	jne 	.skip
	mov 	dword[eax], 0x00FFFFFF
	.skip:
	add 	eax, 4
	inc 	edx
	jmp 	.x_loop
	
.x_end:
	inc 	ecx
	call 	gfx_map
	mov 	ebx, ecx
	imul 	ebx, 4*WIDTH
	add 	eax, ebx
	jmp 	.y_loop
	
.vege:
	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	eax
	ret



;Be: ESI - keret tomb (megfelelo 4 koordinatara allitva)
resize:
	push 	eax
	push 	ebx
	push 	ecx
	push	edx
	push 	esi
	push 	edi
	
	mov 	dword[index], 0

	mov 	eax, [esi]		;EAX - top
	mov 	ecx, [esi+4]
	sub 	ecx, eax		;ECX - height
	sub 	eax, 40
	add 	ecx, 80
	
	add 	esi, 8
	mov 	ebx, [esi]		;EBX - left
	mov 	edx, [esi+4]
	sub 	edx, ebx		;EDX - width
	sub 	ebx, 40
	add 	edx, 80
	
	cmp 	ecx, edx
	je 		.ratio
	cmp		ecx, edx
	jg 		.width_adjust
	
	push 	edx
	sub 	edx, ecx		;EDX - kulonbeg
	push 	eax
	mov 	eax, edx
	cdq
	mov 	ecx, 2
	idiv 	ecx				;EAX - kulonbseg fele
	pop 	ecx
	sub		ecx, eax
	mov 	eax, ecx		;EAX - modositott top szelsoertek
	pop 	edx
	mov 	ecx, edx
	jmp 	.ratio
	
	
	.width_adjust:
		push 	ecx
		sub 	ecx, edx		;ECX - kulonbseg
		push 	eax
		push 	edx
		mov 	eax, ecx
		mov 	ecx, 2
		cdq
		idiv 	ecx				;EAX - kulonbseg fele
		pop 	edx
		sub 	ebx, eax		;EBX - modositott left szelsoertek
		pop 	eax
		pop 	ecx
		mov 	edx, ecx
		
	.ratio:					;ECX = EDX = meret
	push 	eax
	mov 	eax, edx
	mov 	ecx, 28
	cdq
	idiv 	ecx
	inc 	eax
	mov 	edx, eax
	mov 	ecx, eax		;ECX = EDX = meret/28 + 1
	pop 	eax

	
	mov 	esi, eax
	call 	gfx_map
	imul 	esi, 4*WIDTH
	add 	eax, esi
	imul 	ebx, 4
	add 	eax, ebx
	
	mov 	esi, 0xFFFFFF
	cvtsi2ss 	xmm1, esi
	xor 	esi, esi
	
	.mainloop_y:
		cmp 	esi, 28
		je 		.vege
		
		xor 	edi, edi
		
		.mainloop_x:
			cmp 	edi, 28
			je 		.main_x_end
			
			xor 	ebx, ebx
			
			.y_loop:
				cmp 	ebx, ecx
				je 		.y_end
				
				push 	ebx
				xor 	ebx, ebx
				xorps 	xmm5, xmm5
				
				.x_loop:
					cmp 	ebx, edx
					je 		.x_end
					
					push 	ebx
					mov 	ebx, dword[eax]
					cmp 	ebx, 0xFFFFFF
					jne 	.tovabb_1
					addss 		xmm5, [egy]
					
					.tovabb_1:
					pop 	ebx
					
					add 	eax, 4
					inc 	ebx
					jmp 	.x_loop
					
				.x_end:
					pop 	ebx
					inc 	ebx
					add 	eax, 4*WIDTH		;Kovetkezo sorba ugras
					push 	edx
					imul 	edx, 4
					sub 	eax, edx			;Sor elejere allitas
					pop 	edx
					jmp 	.y_loop
					
			.y_end:
				inc 	edi
				push 	ecx
				imul 	ecx, edx
				
				cvtsi2ss	xmm2, ecx
				divss 		xmm5, xmm2
				movss 		xmm0, xmm5
				pop 	ecx		
				
				push 	edi
				push 	eax
				mov 	edi, image
				mov 	eax, dword[index]
				imul 	eax, 4
				add 	edi, eax
				pop 	eax
				movss 	[edi], xmm0
				push 	eax
				mov 	eax, dword[index]
				inc 	eax
				mov 	[index], eax
				pop 	eax
				pop 	edi
				
				movss 		xmm1, [mean]	;normalizalas
				subss 		xmm0, xmm1
				movss 		xmm1, [std_val]
				divss 		xmm0, xmm1
				
				push 	edx
				mov 	edx, in_params
				
				push 	esi			;ESI. sor
				imul 	esi, 28*4
				add 	edx, esi
				pop 	esi
				
				push 	edi			;EDI. oszlop
				imul 	edi, 4
				add 	edx, edi
				pop 	edi
				
				movss 	[edx], xmm0 
				pop 	edx
				
				push 	ecx
				imul 	ecx, 4*WIDTH		;Kovetkezo pixeltombre ugras
				sub 	eax, ecx
				pop 	ecx
				
				push 	edx
				imul 	edx, 4
				add 	eax, edx
				pop 	edx
				
				jmp 	.mainloop_x
				
		.main_x_end:
			inc 	esi
			
			push 	ecx				;Kovetkezo sor elso pixeltombjere ugras
			imul 	ecx, 4*WIDTH
			add 	eax, ecx
			pop 	ecx
			
			push 	edx
			imul 	edx, 4*28
			sub 	eax, edx
			pop 	edx
			
			jmp 	.mainloop_y
			
	.vege:
		pop 	edi
		pop 	esi
		pop 	edx
		pop 	ecx
		pop 	ebx
		pop 	eax
	
	ret


;Be: ESI, EDI - stringek kezdocimei
;Ki: Carry: 1 ha megegyeznek, 0 ha nem
str_compare:
	push 	eax
	push 	esi
	push 	edi
	xor 	eax, eax
	
	.loop:
		lodsb
		cmp 	al, 0
		je 		.vege
		cmp 	al, byte[edi]
		jne 	.nem_egyezik
		inc 	edi
		jmp 	.loop
		
	.nem_egyezik:
		pop 	edi
		pop 	esi
		pop 	eax
		clc
		ret
		
	.vege:
		mov 	eax, [edi]
		cmp 	al, 0
		jne 	.nem_egyezik
		pop 	edi
		pop 	esi
		pop 	eax
		stc
		
	ret



main:
	mov 	eax, WIDTH
	mov 	ebx, HEIGHT
	mov 	ecx, 0
	mov 	edx, windowTitle
	call 	gfx_init				;Ablak letrehozasa
	
	test 	eax, eax				;Ha nem sikerult letrehozni az ablakot, a program leall
	jnz 	.init
	mov 	eax, errorMessage
	call 	io_writestr
	ret
	
.init:
	mov 	eax, infoMessage
	call 	io_writestr
	
.mainloop:						;Az alap felulet kirajzolasa
	xor 	ecx, ecx
	call 	gfx_map
	
.y_loop:
	cmp 	ecx, HEIGHT
	jge 	.startButton
	
	xor 	edx, edx
	
.x_loop:
	cmp 	edx, HEIGHT
	jg		.panel
	
	mov 	ebx, 0
	mov 	[eax], ebx
	add 	eax, 4
	inc 	edx
	jmp 	.x_loop
	
.panel:							;Az ablak jobb oldalan egy, a rajzfelulethez nem tartozo szurke panel talalhato, a ket gombbal, es (kesobb) a felismert szamjegyekkel
	cmp 	edx, WIDTH
	jge 	.x_end
	mov 	ebx, 0x00d6d6d6
	mov 	[eax], ebx
	add 	eax, 4
	inc 	edx
	jmp 	.panel
	
.startButton:					;Kezdogomb beallitasai
	mov 	ebx, 0x0062FF00
	mov 	esi, START_BUTTON_Y*4*WIDTH+START_BUTTON_X*4
	jmp 	.button
	
.resetButton:					;Torlogomb beallitasai
	mov 	ebx, 0x000000ff
	mov 	esi, RESET_BUTTON_Y*4*WIDTH+RESET_BUTTON_X*4
	mov 	[button_1], byte 1
	jmp 	.button
	
	
.button:						;Egy gomb kirajzolasa
	call 	gfx_map
	add 	eax, esi
	xor 	ecx, ecx

	.ybutton:
		cmp 	ecx, BUTTON_HEIGHT
		jge 	.draw
		
		xor 	edx, edx
		
	.xbutton:
		cmp 	edx, BUTTON_WIDTH
		jge 	.xbuttonend
		
		mov 	[eax], ebx
		add 	eax, 4
		inc 	edx
		jmp 	.xbutton
		
	.xbuttonend:
		inc 	ecx
		add 	eax, 4*WIDTH-4*BUTTON_WIDTH
		jmp 	.ybutton
	
.x_end:
	inc 	ecx
	jmp 	.y_loop
	
.draw:						;Alap felulet es gombok kirajzolasa
	cmp 	byte [button_1], 0
	je 		.resetButton
	mov 	byte[button_1], 0
	call 	gfx_unmap
	call 	gfx_draw
	
.input:						;Bemenet lekezelese
	call 	gfx_getevent
	cmp 	eax, 23
	je 		.end
	cmp		eax, 27
	je 		.end
	
	cmp 	eax, 1
	jne 	.mouse
	mov 	byte[mousepressed], 1
	jmp 	.input
	
.draw2:						;Ablak tartalmanak ujra kirajzolasa
	call 	gfx_unmap
	call 	gfx_draw
	jmp 	.input
	
.mouse:
	cmp 	eax, -1
	jne 	.mouse2
	mov 	byte[mousepressed], 0
	jmp 	.input
	
.mouse2:
	cmp		byte[mousepressed], 0
	je		.input
	call 	gfx_getmouse
	
	cmp 	eax, RESET_BUTTON_X						;Ha a torlogombot nyomjuk meg, a program visszaugrik az elso kirajzolashoz
	jl 		.not_reset
	cmp 	ebx, RESET_BUTTON_Y
	jl 		.not_reset
	cmp 	eax, RESET_BUTTON_X+BUTTON_WIDTH
	jg 		.not_reset
	cmp 	ebx, RESET_BUTTON_Y+BUTTON_HEIGHT
	jg 		.not_reset
		
	jmp 	.mainloop
	
	.not_reset:									;A kezdogomb lenyomasakor a szamjegyek bekeretezese es tovabbi feldolgozasa kovetkezik
	cmp 	eax,START_BUTTON_X
	jl 		.not_start
	cmp 	ebx, START_BUTTON_Y
	jl 		.not_start
	cmp 	eax, START_BUTTON_X+BUTTON_WIDTH
	jg 		.not_start
	cmp 	ebx, START_BUTTON_Y+BUTTON_HEIGHT
	jg 		.not_start
	
	mov 	edi, keret
	xor 	esi, esi
	jmp 	.detect
	
	.not_start:								;Ha nem lett gomb lenyomva
	cmp 	eax, THICC						;A rajzfelulet legszeleire nem rajzolhatunk hiba elkerulese celjabol
	jle 	.input
	cmp 	eax, HEIGHT-THICC
	jge 	.input
	cmp 	ebx, THICC
	jle 	.input
	cmp 	ebx, HEIGHT-THICC
	jge 	.input
	
	cmp 	eax, HEIGHT
	jg 		.input
	
	sub 	ebx, THICC/2
	imul 	ebx, 4*WIDTH
	sub 	eax, THICC/2
	imul 	eax, 4
	add 	ebx, eax
	
	call 	gfx_map
	add 	eax, ebx
	
	mov 	ecx, THICC-1
	
	.thickness:									;Megfelelo vastagsagu pixelnegyzet kirajzolasa
		push 	ecx
		mov 	ecx, THICC-1
		.pixel:
			mov 	dword[eax], 0x00FFFFFF
			add 	eax, 4
		loop 	.pixel
		pop 	ecx
		add 	eax, WIDTH*4-(THICC-1)*4
	loop 	.thickness
	jmp 	.draw2
	
	
.detect:									;Szamjegyek kulonvalasztasa
	mov 	byte[mousepressed], 0
	xor 	ecx, ecx
	call 	gfx_map
	
.detecty:
	cmp 	ecx, HEIGHT
	jge 	.square
	
	xor 	edx, edx
	
.detectx:
	cmp 	edx, HEIGHT
	jge		.det_x_end
	
	cmp 	dword[eax], 0x00FFFFFF
	jne 	.not_white

	call 	backtrack					;Egy adott szamjegy megkeresese a rajzon
	inc 	esi
	
	mov 	ebx, dword[top]				;Szelsoertek koordinatak kimentese tombbe
	sub 	ebx, 5
	mov 	dword[top], ebx
	mov 	[edi], ebx
	add 	edi, 4
	mov 	ebx, dword[bottom]
	add 	ebx, 5
	mov 	dword[bottom], ebx
	mov 	[edi], ebx
	add 	edi, 4
	mov 	ebx, dword[left]
	sub 	ebx, 5
	mov 	dword[left], ebx
	mov 	[edi], ebx
	add 	edi, 4
	mov 	ebx, dword[right]
	add 	ebx, 5
	mov 	dword[right], ebx
	mov 	[edi], ebx
	add 	edi, 4
	
	mov 	ebx, 0
	mov 	dword[bottom], ebx
	mov 	dword[right], ebx
	mov 	ebx, HEIGHT
	mov 	dword[top], ebx
	mov 	dword[left], ebx
	
	jmp 	.detect
	
	.not_white:
	add 	edx, 5				;Hatekonysagjavitas celjabol a fekete pixeleken vizszintesen es fuggolegesen is otossevel haladunk keresztul
	add 	eax, 20
	jmp 	.detectx
	
.det_x_end:
	add 	ecx, 5
	mov 	ebx, ecx
	imul 	ebx, 4*WIDTH
	call 	gfx_map
	add 	eax, ebx
	jmp 	.detecty
	
	
.square:					;Szamjegyek bekeretezese
	call 	back_to_white
	mov 	eax, nrnumber	;Kiiratjuk a kulonbozo osszefuggo komponensek/szamjegyek szamat
	call 	io_writestr
	mov 	eax, esi
	push 	esi
	call 	io_writeint
	call 	io_writeln
	
	mov 	edi, keret
	
	.draw_square:			;Keretek kirajzolasa
	cmp 	esi, 0
	je 		.scale
	
	dec 	esi
	call 	gfx_map
	
	mov 	ebx, [edi]
	add 	edi, 4
	mov 	ecx, [edi]
	add 	edi, 4
	sub 	ecx, ebx
	imul 	ebx, 4*WIDTH
	add 	eax, ebx
	
	mov 	ebx, [edi]
	add 	edi, 4
	mov 	edx, [edi]
	add 	edi, 4
	sub 	edx, ebx
	imul 	ebx, 4
	add 	eax, ebx
	
	push 	eax
	push 	ecx
	push 	edx
	
	.horizontal:
		cmp 	edx, 0
		je 		.vertical
		
		mov 	dword[eax], 0x0000FF00
		add 	eax, 4
		dec 	edx
		jmp 	.horizontal
		
	.vertical:
		cmp 	ecx, 0
		je 		.second_half
		
		mov 	dword[eax], 0x0000FF00
		add 	eax, WIDTH*4
		dec 	ecx
		jmp 	.vertical
		
	.second_half:
		pop 	edx
		pop 	ecx
		pop 	eax
		
	.vertical2:
		cmp 	ecx, 0
		je 	.horizontal2
		
		mov 	dword[eax], 0x0000FF00
		add 	eax, WIDTH*4
		dec 	ecx
		jmp 	.vertical2
		
	.horizontal2:
		cmp 	edx, 0
		je 		.draw_square
		
		mov 	dword[eax], 0x0000FF00
		add 	eax, 4
		dec 	edx
		jmp 	.horizontal2
		
		
		
.scale:
	call 	gfx_unmap
	call 	gfx_draw
	
	
	
	mov 	eax, txt_file
	mov 	ebx, 0
	call 	fio_open
	
	test 	eax, eax
	jnz 	.read
	
	mov 	eax, fileError
	call 	io_writestr
	ret
	
.read:
	mov 	ebx, karakter
	mov 	ecx, 1
	mov 	esi, sorrend
	
	.readloop:
	call 	fio_read
	cmp 	byte[ebx], '('
	jne 	.readloop
	
	mov 	ebx, 1
	mov 	ecx, 5
	call 	fio_seek
	mov 	edi, parancs
	
	.utasitash:
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		xor 	edx, edx
		mov 	edx, [karakter]
		
		cmp 	dl, '9'
		jle 	.szamjegy
		
		mov 	[edi], dl
		inc 	edi
		jmp 	.utasitash
		
	.szamjegy:
		mov 	byte[edi], 0
		mov 	edi, parancs
		push 	esi
		mov 	esi, str_conv
		call 	str_compare
		jc 		.conv
		mov 	esi, str_relu
		call 	str_compare
		jc 		.relu
		mov 	esi, str_pool
		call 	str_compare
		jc 		.pool
		mov 	esi, str_linear
		call 	str_compare
		jc 		.linear
		jmp 	.softmax
		
		
	.conv:
		pop 	esi
		mov 	dword[esi], 1
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 22
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		.szam:
		xor 	edx, edx
		mov 	dl, byte[karakter]
		cmp 	dl, '0'
		jl 		.tovabb
		cmp 	dl, '9'
		jg 		.tovabb
		sub 	dl, '0'
		push 	eax
		mov 	eax, dword[szam]
		imul 	eax, 10
		add 	eax, edx
		mov 	[szam], eax
		pop 	eax
		call 	fio_read
		jmp 	.szam
		
		.tovabb:
			push 	eax
			mov 	eax, dword[szam]
			mov 	[esi], eax
			pop 	eax
			mov 	dword[szam], 0
			add 	esi, 4
			mov 	ebx, 1
			mov 	ecx, 14
			call 	fio_seek
			
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		.szam2:
		xor 	edx, edx
		mov 	dl, byte[karakter]
		cmp 	dl, '0'
		jl 		.tovabb2
		cmp 	dl, '9'
		jg 		.tovabb2
		sub 	dl, '0'
		push 	eax
		mov 	eax, dword[szam]
		imul 	eax, 10
		add 	eax, edx
		mov 	[szam], eax
		pop 	eax
		call 	fio_read
		jmp 	.szam2
		
		.tovabb2:
		push 	eax
		mov 	eax, dword[szam]
		mov 	[esi], eax
		pop 	eax
		mov 	dword[szam], 0
		add 	esi, 4
		mov 	ebx, 1
		mov 	ecx, 45
		call 	fio_seek
			
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		xor 	edx, edx
		mov 	dl, byte[karakter]
		sub 	dl, '0'
		mov 	[esi], edx
		add 	esi, 4
		mov 	ebx, 1
		mov 	ecx, 10
		call 	fio_seek
		jmp 	.utasitash
		
		
	.relu:
		pop 	esi
		mov 	dword[esi], 2
		add 	esi, 4
		mov 	ebx, 1
		mov 	ecx, 14
		call 	fio_seek
		jmp 	.utasitash
		
		
	.pool:
		pop 	esi
		mov 	dword[esi], 3
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 25
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		xor	 	edx, edx
		mov 	dl, byte[karakter]
		sub 	dl, '0'
		mov 	[esi], edx
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 9
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		xor	 	edx, edx
		mov 	dl, byte[karakter]
		sub 	dl, '0'
		mov 	[esi], edx
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 10
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		xor	 	edx, edx
		mov 	dl, byte[karakter]
		sub 	dl, '0'
		mov 	[esi], edx
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 11
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		xor	 	edx, edx
		mov 	dl, byte[karakter]
		sub 	dl, '0'
		mov 	[esi], edx
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 12
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		mov 	dword[esi], 1
		xor	 	edx, edx
		mov 	dl, byte[karakter]
		cmp 	dl, 'F'
		jne 	.tovabb3
		mov 	dword[esi], 0
		.tovabb3:
		add 	esi, 4
		mov 	ebx, 1
		mov 	ecx, 10
		call 	fio_seek
		jmp 	.utasitash
		
		
	.linear:
		pop 	esi
		mov 	dword[esi], 4
		add 	esi, 4
		
		mov 	ebx, 1
		mov 	ecx, 22
		call 	fio_seek
		
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		.szam3:
		xor 	edx, edx
		mov 	dl, byte[karakter]
		cmp 	dl, '0'
		jl 		.tovabb4
		cmp 	dl, '9'
		jg 		.tovabb4
		sub 	dl, '0'
		push 	eax
		mov 	eax, dword[szam]
		imul 	eax, 10
		add 	eax, edx
		mov 	[szam], eax
		pop 	eax
		call 	fio_read
		jmp 	.szam3
		
		.tovabb4:
			push 	eax
			mov 	eax, dword[szam]
			mov 	dword[esi], eax
			pop 	eax
			mov 	dword[szam], 0
			add 	esi, 4
			mov 	ebx, 1
			mov 	ecx, 14
			call 	fio_seek
			
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		.szam4:
		xor 	edx, edx
		mov 	dl, byte[karakter]
		cmp 	dl, '0'
		jl 		.tovabb5
		cmp 	dl, '9'
		jg 		.tovabb5
		sub 	dl, '0'
		push 	eax
		mov 	eax, dword[szam]
		imul 	eax, 10
		add 	eax, edx
		mov 	[szam], eax
		pop 	eax
		call 	fio_read
		jmp 	.szam4
		
		.tovabb5:
			push 	eax
			mov 	eax, dword[szam]
			mov 	dword[esi], eax
			pop 	eax
			mov 	dword[szam], 0
			add 	esi, 4
			mov 	ebx, 1
			mov 	ecx, 6
			call 	fio_seek
			
		mov 	ebx, karakter
		mov 	ecx, 1
		call 	fio_read
		
		mov 	dword[esi], 1
		xor	 	edx, edx
		mov 	dl, byte[karakter]
		cmp 	dl, 'F'
		jne 	.tovabb6
		mov 	dword[esi], 0
		.tovabb6:
		add 	esi, 4
		mov 	ebx, 1
		mov 	ecx, 9
		call 	fio_seek
		jmp 	.utasitash
		
		
	.softmax:
		pop 	esi
		mov 	dword[esi], 5
	
	mov 	eax, str_end
	call 	io_writestr
	pop 	ecx				;ECX - komponensek szama
	mov 	esi, keret
	mov		dword[lefele], 0
	
	.scale_loop:
		cmp 	ecx, 0
		je 		.detect_end
		call 	resize
		add 	esi, 16	
		call 	NeuralNetwork
		call 	io_writeint
		mov 	eax, vesszo
		call 	io_writestr
		dec 	ecx
		jmp 	.scale_loop
		
	.detect_end:
		mov 	eax, torles
		call 	io_writestr
		call 	io_writeln
		jmp 	.draw2
	
.end:							;Program leallitasa/vege
	mov 	eax, endMessage
	call 	io_writestr
	call 	gfx_destroy
	ret
	
	
	
section .data
	windowTitle 	db 'Project', 0
	infoMessage 	db 'Rajzoljon egerrel a fekete rajzfeluletre! Ugyeljen a vonalak folytonossagara!', 10, 'A rajzfeluletet a kek gombbal torolheti.', 10, 'A szamjegyek felismereset a zold gombbal indithatja el.', 10, 0
	errorMessage 	db 'Nem sikerult letrehozni az ablakot!', 0
	endMessage 		db 'Leallitotta a programot', 10, 0
	nrnumber 		db 'Beirt szamjegyek szama: ', 0
	
	button_1 		db 0
	mousepressed 	db 0
	
	top			dd HEIGHT
	bottom		dd 0
	left		dd HEIGHT
	right		dd 0
	
	pixel 		dd 0
	mean 		dd 0.1307
	std_val 	dd 0.3081
	
	txt_file 		db 'cnn_no_pad.txt', 0
	bin_file 		db 'cnn_no_pad.bin', 0
	fileError 		db 'Nem sikerult megnyitni a filet', 0
	str_softmax 	db 'softmax', 0
	str_conv 		db 'conv', 0
	str_relu 		db 'relu', 0
	str_pool 		db 'pool', 0
	str_linear 		db 'fc', 0
	szam 			dd 0
	
	str_end			db 'A talalt szamjegy(ek): ', 0
	vesszo 			db ', ', 0
	torles 			db 8, 8, '  ', 8, 8, 0
	str_neural 		db 'Neural', 0
	bin_params 		dd 0
	
	
	parameterek 	db 'Parameterek: ', 0
	memcim 			db 'Memoriacim: ', 0
	poss 			db ' --- ', 0
	index	 		dd 0
	lefele 			dd 0
	egy 			dd 1.0

section .bss
	keret	resd 100
	xmm		resd 4

	sorrend		resd 100
	karakter	resb 1
	parancs 	resb 7
	
	padded 		resd 10000
	in_params 	resd 15000
	out_params 	resd 15000
	bin_paramss 	resd 1600000
	
	
	image 		resd 28*28