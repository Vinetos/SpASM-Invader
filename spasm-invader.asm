; ==============================
; Définition des constantes
; ==============================

 		; Mémoire vidéo
 		; ------------------------------
VIDEO_START 	equ 	$ffb500 ; Adresse de départ
VIDEO_WIDTH 	equ 	480 ; Largeur en pixels
VIDEO_HEIGHT 	equ 	320 ; Hauteur en pixels
VIDEO_SIZE		equ		(VIDEO_WIDTH*VIDEO_HEIGHT/8) ; Taille en octets
BYTE_PER_LINE 	equ 	(VIDEO_WIDTH/8) ; Nombre d'octets par ligne
VIDEO_BUFFER 	equ 	(VIDEO_START-VIDEO_SIZE)

		; Bitmaps
 		; ------------------------------
WIDTH 			equ 0 ; Largeur en pixels
HEIGHT 			equ 2 ; Hauteur en pixels
MATRIX 			equ 4 ; Matrice de points


		; Sprites
		; ------------------------------
STATE 	   		equ 0 ; État de l'affichage
X 				equ 2 ; Abscisse
Y 				equ 4 ; Ordonnée
BITMAP1 		equ 6 ; Bitmap no 1
BITMAP2 		equ 10 ; Bitmap no 2
HIDE 			equ 0 ; Ne pas afficher le sprite
SHOW 			equ 1 ; Afficher le sprite



		; Touches du clavier
 		; ------------------------------
SPACE_KEY 		equ $420
LEFT_KEY 		equ $441  ;$451 = Q
UP_KEY 			equ $457  ;$45A = Z
RIGHT_KEY 		equ $444  ; D
DOWN_KEY 		equ $453  ; S

				; Pas d'incrémentation en pixels
				; ------------------------------
SHIP_STEP       equ		4; Pas du vaisseau
SHIP_SHOT_STEP  equ		4; Pas d'un tir de vaisseau

; ==============================
; Initialisation des vecteurs
; ==============================
 				org 	$0

vector_000 		dc.l 	VIDEO_BUFFER ; Valeur initiale de A7
vector_001 		dc.l 	Main ; Valeur initiale du PC

; ==============================
; Programme principal
; ==============================
				org 	$500

Main            jsr     PrintShip
				jsr     PrintShipShot
				jsr     BufferToScreen
				
				jsr     MoveShip
				jsr     MoveShipShot
				
				jsr     NewShipShot
				
				bra     Main

\loop 			; Affiche le sprite.
				jsr PrintSprite
				jsr BufferToScreen
				; Déplace le sprite en fonction des touches du clavier.
				jsr MoveSpriteKeyboard
				; Reboucle.
				bra \loop

				illegal


; ==============================
; Sous-programmes
; ==============================
MoveSpriteKeyboard						;a1 = adresse du sprite
				movem.l	d1/d2,-(a7)
				clr.w	d1	;déplacement horizontal
				clr.w	d2	; déplacement vertical

\up				tst.b	UP_KEY
				beq		\down
				sub.w	#1,d2
\down			tst.b	DOWN_KEY
				beq		\left
				add.w	#1,d2

\left			tst.b	LEFT_KEY
				beq		\right
				sub.w	#1,d1

\right			tst.b	RIGHT_KEY
				beq		\mouvement
				add.b	#1,d1
				
\mouvement		jsr		MoveSprite

				movem.l	(a7)+,d1/d2
				rts



MoveSprite 		; a1 = adresse du sprite , d1 = déplacement horizontal	, d2 = déplacement vertical
 				movem.l d1/d2/a0,-(a7)

			 	; Le déplacement fait il sortir le Sprite de l'écran ?
				add.w X(a1),d1
 				add.w Y(a1),d2
				movea.l BITMAP1(a1),a0
				jsr IsOutOfScreen
				beq \false
 				; Si ca reste dans l'écran, on modifie les coordonées du sprite + Z =1
				move.w d1,X(a1)
 				move.w d2,Y(a1)
 				ori.b #%00000100,ccr
 				bra \quit
\false 			; Si ca sort de l'écran, on ne modifie rien + Z = 0
 				andi.b #%11111011,ccr
\quit 			movem.l (a7)+,d1/d2/a0
 				rts
 
;----------------------------------------
IsOutOfX		move.l	d3,-(a7)			; a0 = adresse du bitmap , d1 = coordonnée x du pixel du début du bitmap
				tst.w	d1
				bmi		\return_true
				move.w 	WIDTH(a0),d3
				add.w	d1,d3
				cmp.w	#VIDEO_WIDTH,d3
				bhs		\return_true
\return_false	move.l	(a7)+,d3
				andi.b	#%11111011,ccr
				rts

\return_true	move.l	(a7)+,d3
				ori.b	#%00000100,ccr
				rts

;-----------------------------------------
IsOutOfY		move.l	d3,-(a7)			; a0 = adresse du bitmap , d2 = coordonnée y du pixel du début du bitmap
				tst.w	d2
				bmi		\return_true
				move.w 	HEIGHT(a0),d3
				add.w	d2,d3
				cmp.w	#VIDEO_HEIGHT,d3
				bhs		\return_true
\return_false	move.l	(a7)+,d3
				andi.b	#%11111011,ccr
				rts

\return_true	move.l	(a7)+,d3
				ori.b	#%00000100,ccr
				rts
				
;----------------------------------------
				;IsOutOfScreen: No: z = 0, Yes: z = 1
IsOutOfScreen	jsr		IsOutOfX
				beq		\return_true
				jsr		IsOutOfY
				beq		\return_true
\return_false	andi.b	#%11111011,ccr
				rts
\return_true	ori.b	#%00000100,ccr
				rts
								
;----------------------------------------
IsSpriteColliding
				; Sauvegarde des registres
				movem.l	d1-d4/a0,-(a7)
				
				; Pas visible
				cmp.w	#SHOW,STATE(a1)
				bne		\return_false
				cmp.w	#SHOW,STATE(a2)
				bne		\return_false
				
				
				; GetRectangle de 1
				movea.l	a1,a0
				jsr 	GetRectangle
				movem.l	d1-d4,-(a7)
				
				; GetRectangle de 2
				movea.l	a2,a0
				jsr 	GetRectangle
				
				; Comparaison des coordonnees
				cmp.w	4(a7),d1	;a7 = d3 pour 1
				bgt 	\return_false; 1 plus a droite que 2 en x
				
				cmp.w	6(a7),d2 	;a7 = d4 pour 1
				bgt 	\return_false; 1 plus bas que 2 en y
				
				cmp.w	(a7),d3	;a7 = d1 pour 1
				blt 	\return_false; 1 plus a gauche que 2 en x
				
				cmp.w	4(a7),d4	;a7 = d2 pour 1
				blt 	\return_false; 1 plus haut que 2 en y
				

\return_true	; Restauration des registres
				adda.w	#8,a7
				movem.l	(a7)+,d1-d4
				ori.b	#%00000100,ccr
				rts
				

\return_false	; Restauration des registres
				adda	#8,a7
				movem.l	(a7)+,d1-d4
				andi.b	#%11111011,ccr
				rts


;---------------------------------------
GetRectangle	move.l	a0,-(a7)
				;WIDTH, HEIGHT;X, Y
				move.w	X(a0),d1 		; Coin superieur gauche, abs
				move.w	Y(a0),d2 		; ord
				
				movea.l BITMAP1(a0),a0
				
				move.w	d1,d3
				add.w	WIDTH(a0),d3
				sub.w   #1,d3
				
				move.w	d2,d4			; Coin superieur gauche, abs
				add.w	HEIGHT(a0),d4	; ord
				sub.w   #1,d4
				
				movea.l	(a7)+,a0
				rts
;-----------------------------------------
CopyLine		movem.l	d1/d2/d4/d5/a1,-(a7)    ; d0 = décallage en pixel , d3 = largeur de la ligne

				move.b	#8,d5
				sub.b	d0,d5
				clr.l	d1						; d1 = compteur de boucle
\loop			addq.l  #1,d1
				move.b	(a0)+,d2
				move.b	d2,d4
				lsr.b	d0,d4					; d4 = octet de gauche
				lsl.b	d5,d2					; d2 = octet de droite


				or.b	d4,(a1)+
				or.b	d2,(a1)

				cmp.l	d3,d1
				bne		\loop
				movem.l	(a7)+,d1/d2/d4/d5/a1
				rts
			
			

;------------------------------------------
PixelToByte		move.l	d2,-(a7)
				move.l	d3,d2
				lsr.l	#3,d3
				andi.l	#$00000007,d2
				beq		\mult_de8
				addq.l	#1,d3
\mult_de8		move.l	(a7)+,d2
				rts

;------------------------------------------
CopyBitmap		movem.l	d1/d2/d3/a0/a1,-(a7)
				move.w 	WIDTH(a0),d3 ; d3 = largeur du bitmap en pixel
				jsr		PixelToByte  ; d3 = largeur du bitmap en octet

				move.w 	HEIGHT(a0),d1 ; D1 = hauteur du bitmap
				clr.l	d2			  ; d2 servira de compteur de boucle

				lea		MATRIX(a0),a0 ; a0 pointe sur le premier octet du bitmap

\loop			addq.w	#1,d2
				jsr		CopyLine
				adda.l	#BYTE_PER_LINE,a1

				cmp.w	d2,d1
				bne		\loop
				movem.l	(a7)+,d1/d2/d3/a0/a1
				rts
;------------------------------------------------------------------------------
PixelToAdress	movem.l	d1/d2,-(a7)		; d1 = x abscisses du pixel  ,  d2 = y ordonnée du pixel
				mulu.w 	#BYTE_PER_LINE,d2
				lea		VIDEO_BUFFER,a1
				adda.w	d2,a1
				move.w	d1,d2
				lsr.w	#3,d1
				adda.w	d1,a1			; a1 = y*byte_per_line + x/8 (division entière)
				andi.w	#%111,d2
				move.w	d2,d0			; d0 = x modulo 8 (soit les 3 premiers bits de x)
				movem.l	(a7)+,d1/d2
				rts
;--------------------------------------------------------------------------
PrintBitmap		movem.l d0/a1,-(a7)
				jsr		PixelToAdress
				jsr		CopyBitmap
				movem.l (a7)+,d0/a1
				rts
;----------------------------------------------------------------------------
FillScreen		movem.l	a0/a1,-(a7)
				movea.l #VIDEO_BUFFER,a0
				movea.l	#VIDEO_BUFFER+VIDEO_SIZE,a1
				
\loop
 				move.l	d0,(a0)+
 				cmp.l	a1,a0
 				bne		\loop

 				movem.l	(a7)+,a0/a1
 				rts
 				
;----------------------------------------------------------------------------
ClearScreen		move.l	d0,-(a7)
				move.l	#$00000000,d0
				jsr		FillScreen
				move.l	(a7)+,d0
				rts

;-----------------------------------------------------------------------------
BufferToScreen	movem.l	d0/d1/a0/a1,-(a7)
 				move.l	#VIDEO_START,a0
 				move.l	#VIDEO_BUFFER,a1

				move.l	#0,d0
				move.l	#VIDEO_SIZE/4,d1
\loop			addq.l	#1,d0
				move.l	(a1),(a0)+
				move.l	#0,(a1)+
				cmp.l	d0,d1
				bne		\loop
				movem.l	(a7)+,d0/d1/a0/a1
				rts
				
				
;-----------------------------------------------------------------------------
PrintSprite		movem.l	d0/d1/d2/a0,-(a7)
				move.w 	STATE(a1),d0 ; État de l'affichage -> D0.W
 				move.w 	X(a1),d1 ; X -> D1.W
 				move.w 	Y(a1),d2 ; Y -> D2.W
 				movea.l BITMAP1(a1),a0 ; Adresse du bitmap 1 -> A0.L
 				
 				tst.w	d0
 				beq		\quit

 				jsr		PrintBitmap

\quit			movem.l	(a7)+,d0/d1/d2/a0
				rts
				
;-----------------------------------------------------------------------------			
PrintShip		move.l	a1,-(a7)
				lea 	Ship,a1
				jsr		PrintSprite
				move.l	(a7)+,a1
				rts
							
MoveShip		;a1 = adresse du sprite
				movem.l	d1/d2/a1,-(a7)
				lea 	Ship,a1
				clr.w	d1	;déplacement horizontal
				clr.w	d2	; déplacement vertical

\left			tst.b	LEFT_KEY
				beq		\right
				sub.w	#SHIP_STEP,d1

\right			tst.b	RIGHT_KEY
				beq		\mouvement
				add.w	#SHIP_STEP,d1
				
\mouvement		jsr		MoveSprite

				movem.l	(a7)+,d1/d2/a1
				rts

;-----------------------------------------------------------------------------			
PrintShipShot	move.l	a1,-(a7)
				lea 	ShipShot,a1
				jsr		PrintSprite
				move.l	(a7)+,a1
				rts
				
		
MoveShipShot	;a1 = adresse du sprite				
				movem.l	d1/d2/a1,-(a7)
				lea 	ShipShot,a1
				
				cmp.w	#SHOW,STATE(a1)
				bne		\quit
				
				clr.w	d1	;déplacement horizontal
				clr.w	d2	; déplacement vertical

				sub.w	#SHIP_SHOT_STEP,d2
				
				jsr		MoveSprite
				jsr		IsOutOfScreen
				bne		\quit ; Ne sort pas
				
				move.w	#HIDE,STATE(a1)
				

\quit			movem.l	(a7)+,d1/d2/a1
				rts
				

NewShipShot		movem.l	d1/d2/a1/a2,-(a7)
				lea		ShipShot,a1
				lea		Ship,a2
				
				tst.b	SPACE_KEY
				bne		\quit
				
				cmp.w	#SHOW,STATE(a1)
				beq		\quit
				
				move.w	#SHOW,STATE(a1)
				; TODO: when calling this, no move fro; ship
				
				; H ship dans d2
				;move.l 	WIDTH(a2),d1
				;ror.l	#1,d1
				;move.l 	d1,X(a1)
				
				;move.l 	Y(a2),d2
				;sub.l 	HEIGHT(a2),d2
				;add.l	d2,Y(a1)
				
\quit			;movem.l	(a7)+,d1/d2/a1/a2
				rts

; ==============================
; Données
; ==============================
				org		$1000

InvaderA_Bitmap dc.w 	24,16
 				dc.b 	%00000000,%11111111,%00000000
 				dc.b	%00000000,%11111111,%00000000
 				dc.b	%00111111,%11111111,%11111100
 				dc.b 	%00111111,%11111111,%11111100
 				dc.b 	%11111111,%11111111,%11111111
 				dc.b 	%11111111,%11111111,%11111111
 				dc.b 	%11111100,%00111100,%00111111
 				dc.b 	%11111100,%00111100,%00111111
 				dc.b 	%11111111,%11111111,%11111111
 				dc.b 	%11111111,%11111111,%11111111
 				dc.b 	%00000011,%11000011,%11000000
 				dc.b 	%00000011,%11000011,%11000000
 				dc.b 	%00001111,%00111100,%11110000
 				dc.b 	%00001111,%00111100,%11110000
 				dc.b 	%11110000,%00000000,%00001111
 				dc.b 	%11110000,%00000000,%00001111

InvaderB_Bitmap dc.w 	22,16							; Largeur, Hauteur
				dc.b 	%00001100,%00000000,%11000000	; Matrice de Points
 			   	dc.b 	%00001100,%00000000,%11000000
 				dc.b 	%00000011,%00000011,%00000000
 				dc.b 	%00000011,%00000011,%00000000
 				dc.b 	%00001111,%11111111,%11000000
 				dc.b 	%00001111,%11111111,%11000000
 				dc.b 	%00001100,%11111100,%11000000
 				dc.b 	%00001100,%11111100,%11000000
 				dc.b 	%00111111,%11111111,%11110000
 				dc.b 	%00111111,%11111111,%11110000
 				dc.b 	%11001111,%11111111,%11001100
 				dc.b 	%11001111,%11111111,%11001100
 				dc.b 	%11001100,%00000000,%11001100
 				dc.b 	%11001100,%00000000,%11001100
 				dc.b 	%00000011,%11001111,%00000000
 				dc.b 	%00000011,%11001111,%00000000

InvaderC_Bitmap dc.w 16,16
 				dc.b %00000011,%11000000
 				dc.b %00000011,%11000000
 				dc.b %00001111,%11110000
 				dc.b %00001111,%11110000
 				dc.b %00111111,%11111100
 				dc.b %00111111,%11111100
 				dc.b %11110011,%11001111
 				dc.b %11110011,%11001111
 				dc.b %11111111,%11111111
 				dc.b %11111111,%11111111
 				dc.b %00110011,%11001100
 				dc.b %00110011,%11001100
 				dc.b %11000000,%00000011
	 			dc.b %11000000,%00000011
 				dc.b %00110000,%00001100
 				dc.b %00110000,%00001100

Ship_Bitmap 	dc.w 24,14
 				dc.b %00000000,%00011000,%00000000
 				dc.b %00000000,%00011000,%00000000
 				dc.b %00000000,%01111110,%00000000
	 			dc.b %00000000,%01111110,%00000000
 				dc.b %00000000,%01111110,%00000000
 				dc.b %00000000,%01111110,%00000000
 				dc.b %00111111,%11111111,%11111100
 				dc.b %00111111,%11111111,%11111100
 				dc.b %11111111,%11111111,%11111111
 				dc.b %11111111,%11111111,%11111111
 				dc.b %11111111,%11111111,%11111111
 				dc.b %11111111,%11111111,%11111111
 				dc.b %11111111,%11111111,%11111111
 				dc.b %11111111,%11111111,%11111111
 				
ShipShot_Bitmap dc.w	2,6
				dc.b	%11000000
				dc.b	%11000000
				dc.b	%11000000
				dc.b	%11000000
				dc.b	%11000000
				dc.b	%11000000

Invader 		dc.w 	SHOW ; Afficher le sprite
 				dc.w 	0,152 ; X = 0, Y = 152
 				dc.l 	InvaderA_Bitmap ; Bitmap à afficher
				dc.l 	0 ; Inutilisé
				
Ship            dc.w    SHOW
				dc.w	(VIDEO_WIDTH-24)/2,VIDEO_HEIGHT-32
				dc.l    Ship_Bitmap
				dc.l	0
				
ShipShot        dc.w    HIDE
				dc.w	0,0
				dc.l    ShipShot_Bitmap
				dc.l	0
				
MovingSprite    dc.w    SHOW
				dc.w	0,152
				dc.l    ShipShot_Bitmap
				dc.l	0
