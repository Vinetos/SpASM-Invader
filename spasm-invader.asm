; ==============================
; Définition des constantes
; ==============================

 		; Mémoire vidéo
 		; ------------------------------
VIDEO_START 	equ    $ffb500 ; Adresse de départ
VIDEO_WIDTH 	equ    480 ; Largeur en pixels
VIDEO_HEIGHT 	equ    320 ; Hauteur en pixels
VIDEO_SIZE 	equ    (VIDEO_WIDTH*VIDEO_HEIGHT/8) ; Taille en octets
BYTE_PER_LINE 	equ    (VIDEO_WIDTH/8) ; Nombre d'octets par ligne
VIDEO_BUFFER 	equ    (VIDEO_START-VIDEO_SIZE)

		; Bitmaps
 		; ------------------------------
WIDTH           equ 0 ; Largeur en pixels
HEIGHT          equ 2 ; Hauteur en pixels
MATRIX          equ 4 ; Matrice de points


		; Sprites
		; ------------------------------
STATE 	        equ 0 ; État de l'affichage
X 		equ 2 ; Abscisse
Y 		equ 4 ; Ordonnée
BITMAP1 	equ 6 ; Bitmap no 1
BITMAP2 	equ 10 ; Bitmap no 2
HIDE 		equ 0 ; Ne pas afficher le sprite
SHOW 		equ 1 ; Afficher le sprite
SIZE_OF_SPRITE 	equ 14 ; Taille d'un sprite en octets

		; Envahisseurs
		; ------------------------------
INVADER_PER_LINE 	equ 10
INVADER_PER_COLUMN 	equ 5
INVADER_COUNT 		equ INVADER_PER_LINE*INVADER_PER_COLUMN


		; Touches du clavier
 		; ------------------------------
SPACE_KEY 	equ $420
LEFT_KEY 	equ $451  ; Q
UP_KEY 		equ $45A  ; Z
RIGHT_KEY 	equ $444  ; D
DOWN_KEY 	equ $453  ; S

		; Pas d'incrémentation en pixels
		; ------------------------------
SHIP_STEP 	equ 4 ; Pas du vaisseau
SHIP_SHOT_STEP 	equ 4

		; Déplacement global des invaders
		;--------------------------------
INVADER_STEP_X  equ 4
INVADER_STEP_Y  equ 8
INVADER_X_MIN   equ 0
INVADER_X_MAX   equ (VIDEO_WIDTH-(INVADER_PER_LINE*32))


; ==============================
; Initialisation des vecteurs
; ==============================
 		org 	$0

vector_000 	dc.l 	VIDEO_BUFFER ; Valeur initiale de A7
vector_001 	dc.l 	Main ; Valeur initiale du PC


; ==============================
; Programme principal
; ==============================

                org 	$500

Main 		jsr InitInvaders

\loop 		jsr PrintShip
 		jsr PrintShipShot
		jsr PrintInvaders
		jsr BufferToScreen

		jsr DestroyInvaders

 		jsr MoveShip
		jsr MoveInvaders
		jsr MoveShipShot

		jsr NewShipShot

		bra \loop

; ==============================
; Sous-programmes
; ==============================

DestroyInvaders movem.l	d0/a1-a2,-(a7)

		move.w	#INVADER_COUNT,d0
		lea	Invaders,a1
		lea     ShipShot,a2

\loop           jsr     IsSpriteColliding
                bne     \continue

                move.w	#HIDE,STATE(a1)
                move.w	#HIDE,STATE(a2)
                sub.w   #1,InvaderCount
                bra     \quit

\continue	adda.l	#SIZE_OF_SPRITE,a1
		sub.w	#1,d0
		beq	\quit
		bra	\loop

\quit		movem.l	(a7)+,d0/a1-a2
		rts

SwapBitmap	;a1 = adresse du sprite ou il faut inverser Bitmap1 et 2
		movem.l	a2/a3,-(a7)
		move.l	BITMAP1(a1),a2
		move.l	BITMAP2(a1),a3
		move.l	a3,BITMAP1(a1)
		move.l	a2,BITMAP2(a1)
		movem.l	(a7)+,a2/a3
		rts


MoveInvaders	movem.l	d0/a0,-(a7)
		lea	Cpt_MoveInvaders,a0
		move.w	(a0),d0
		cmp.w	#8,d0
		beq	\mvt
		add.w	#1,d0
		bra	\quit

\mvt		jsr	MoveAllInvaders
		move.w	#1,d0
		bra	\quit
\quit		move.w	d0,(a0)
		movem.l	(a7)+,d0/a0
		rts

MoveAllInvaders movem.l	d0/d1/d2/a1,-(a7)
		jsr	GetInvaderStep
		move.w	#INVADER_COUNT,d0
		lea	Invaders,a1
\loop		jsr	MoveSprite
		jsr	SwapBitmap
		adda.l	#SIZE_OF_SPRITE,a1
		sub.w	#1,d0
		beq	\quit
		bra	\loop

\quit		movem.l	(a7)+,d0/d1/d2/a1
		rts

;--------------------------------------------------

GetInvaderStep     move.l	d0,-(a7)
                   move.w	InvaderX,d0
		   add.w	InvaderCurrentStep,d0

		   ; Est ce que invaderX < Xmin ?
		   cmp.w	#INVADER_X_MIN,d0
		   blo		\changement

		   ; Est ce que InvaderX > Xmax ?
		   cmp.w	#INVADER_X_MAX,d0
		   bhi		\changement

		   ; Si aucun changement
		   move.w	InvaderCurrentStep,d1
		   move.w	#0,d2
		   move.w	d0,InvaderX
		   bra		\quit

		   ; Si changement
\changement	   move.w	#0,d1
		   move.w	#INVADER_STEP_Y,d2
		   add.w	d2,InvaderY
		   neg.w	InvaderCurrentStep

\quit		   move.l	(a7)+,d0
		   rts

;--------------------------------------------------------------
InitInvaders    movem.l	d1/d2/a0-a2,-(a7)

		move.w InvaderX,d1
 		move.w InvaderY,d2
     		lea Invaders,a0
		lea InvaderC1_Bitmap,a1
		lea InvaderC2_Bitmap,a2
 		jsr InitInvaderLine

 		add.w	#32,d2
 		lea InvaderB1_Bitmap,a1
 		lea InvaderB2_Bitmap,a2
 		adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
		jsr InitInvaderLine

		add.w	#32,d2
		adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
 		jsr InitInvaderLine

		add.w	#32,d2
 		lea InvaderA1_Bitmap,a1
 		lea InvaderA2_Bitmap,a2
 		adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
 		jsr InitInvaderLine

		add.w	#32,d2
		adda.l #SIZE_OF_SPRITE*INVADER_PER_LINE,a0
 		jsr InitInvaderLine

 		movem.l	(a7)+,d1/d2/a0-a2
 		rts
;-----------------------------------------------------------------
InitInvaderLine	; d1 = x coin sup gauche ligne	, d2 = y coin sup gauche ligne
		; a0 = adresse struct 1er envahisseur , a1 = bitmap1, a2 bitmap2
		movem.l	d1-d4/a0,-(a7)
		; recentrage :d1 = d1+(32-WIDTH(a1))/2
		move.w 	#32,d3
		sub.w	WIDTH(a1),d3
		lsr.w	#1,d3
		add.w	d3,d1

		move.w	#INVADER_PER_LINE,d4
\loop		move.w	#SHOW,STATE(a0)
		move.w	d1,X(a0)
		move.w	d2,Y(a0)
		move.l	a1,BITMAP1(a0)
		move.l	a2,BITMAP2(a0)
		
                add.w	#32,d1
		add.l	#SIZE_OF_SPRITE,a0
		sub.w	#1,d4
		bne	\loop

		movem.l	(a7)+,d1-d4/a0
		rts

;---------------------------------------------------
PrintInvaders	movem.l	d1/a1,-(a7)
		move.w	#INVADER_COUNT,d1
		lea	Invaders,a1

\loop		jsr	PrintSprite
		adda.l	#SIZE_OF_SPRITE,a1
		sub.w	#1,d1
		bne	\loop
		movem.l	(a7)+,d1/a1
		rts

;-----------------------------------------
NewShipShot	movem.l	d0-d5/a0/a1,-(a7)
		; si touche espace relachée, on ne fait rien
		tst.b	SPACE_KEY
		beq	\quit
		; sinon si il y a déjà un tir à l'écran, on ne fait rien
		lea	ShipShot,a0
		cmp.w	#SHOW,STATE(a0)
		beq	\quit

		; sinon on crée un nouveau tir
		move.w	#SHOW,STATE(a0)
		lea	Ship,a1
		move.w	X(a1),d0			; d0 = coordonnée X du sprite Ship
		move.w	Y(a1),d1			; d1 = coordonnée Y du sprite Ship
		movea.l	BITMAP1(a1),a1
		move.w	WIDTH(a1),d2			; d2 = Largeur Bitmap Ship
		move.w	HEIGHT(a1),d3			; d3 = Hauteur Bitmap Ship


		movea.l	BITMAP1(a0),a1
		move.w	WIDTH(a1),d4			; d4 = Largeur Bitmap Shot
		move.w	HEIGHT(a1),d5			; d5 = Hauteur Bitmap Shot

		; calcul des coordonnées intiales de Shot
		lsr.w	#1,d2
		sub.w	#1,d2
		add.w	d2,d0
		move.w	d0,X(a0)

		sub.w	d5,d1
		move.w	d1,Y(a0)

				

\quit		movem.l	(a7)+,d0-d5/a0/a1
		rts


;-----------------------------------------
PrintShipShot	move.l	a1,-(a7)
		lea     ShipShot,a1
		jsr	PrintSprite
		move.l	(a7)+,a1
		rts
				
;------------------------------------------
MoveShipShot	movem.l	d1/d2/a1,-(a7)
		lea	ShipShot,a1

		tst.w	STATE(a1)
		beq	\quit

		clr.w	d1					;déplacement horizontal
		move.w	#-SHIP_SHOT_STEP,d2	;déplacement vertical = 0 obligatoirement

		jsr	MoveSprite			; Z = 0 -> sort de l'écran  , Z = 1 -> dans l'écran
		beq	\quit				; ???? pour pas bne

\OutOfScreen	move.w	#HIDE,STATE(a1)

\quit		movem.l	(a7)+,d1/d2/a1
		rts

;------------------------------------------
PrintShip	move.l	a1,-(a7)
		lea Ship,a1
		jsr	PrintSprite
		move.l	(a7)+,a1
		rts
;------------------------------------------
MoveShip	movem.l	d1/d2/a1,-(a7)
		lea	Ship,a1
		clr.w	d1	;déplacement horizontal
		clr.w	d2	;déplacement vertical = 0 obligatoirement
\left		tst.b	LEFT_KEY
		beq		\right
		sub.w	#SHIP_STEP,d1

\right		tst.b	RIGHT_KEY
		beq		\mouvement
		add.b	#SHIP_STEP,d1
\mouvement	jsr		MoveSprite

		movem.l	(a7)+,d1/d2/a1
                rts
;----------------------------------------------------

IsSpriteColliding  ; Sauvegarde les registres.
                   movem.l d1-d4/a0,-(a7)
                   
                   ; Si les sprites ne sont pas visibles, on quitte.
                   ; Le BNE saute si Z = 0, on renvoie donc false.
                   ; On ne peut pas effectuer un BNE \false tout de suite,
                   ; car ce dernier pase par le nettoyage de la pile.
                   cmp.w #SHOW,STATE(a1)
                   bne \quit
                   cmp.w #SHOW,STATE(a2)
                   bne \quit
                   
                   ; Coordonnées du rectangle 1 -> Pile
                   ; D1.W -> (a7) ; x1 = Abscisse du point supérieur gauche
                   ; D2.W -> 2(a7) ; y1 = Ordonnée du point supérieur gauche
                   ; D3.W -> 4(a7) ; X1 = Abscisse du point inférieur droit
                   ; D4.W -> 6(a7) ; Y1 = Ordonnée du point inférieur droit
                   movea.l a1,a0
                   jsr GetRectangle
                   movem.w d1-d4,-(a7)
                   
                   ; Coordonnées du rectangle 2 -> D1-D4
                   ; D1.W = x2 = Abscisse du point supérieur gauche
                   ; D2.W = y2 = Ordonnée du point supérieur gauche
                   ; D3.W = X2 = Abscisse du point inférieur droit
                   ; D4.W = Y2 = Ordonnée du point inférieur droit
                   movea.l a2,a0
                   jsr GetRectangle
                   
                   ; Si x2 > X1, on renvoie false.
                   cmp.w 4(a7),d1
                   bgt \false
                   
                   ; Si y2 > Y1, on renvoie false.
                   cmp.w 6(a7),d2
                   bgt \false
                   
                   ; Si X2 < x1, on renvoie false.
                   cmp.w (a7),d3
                   blt \false
        
                   ; Si Y2 < y1, on renvoie false.
                   cmp.w 2(a7),d4
                   blt \false

\true              ; Sortie qui renvoie true (Z = 1).
                   ori.b #%00000100,ccr
                   bra \cleanStack

\false             ; Sortie qui renvoie false (Z = 0).
                   andi.b #%11111011,ccr

\cleanStack        ; Dépile les coordonnées du rectangle 1.
                   ; (L'instruction ADDA ne modifie pas les flags.)
                   adda.l #8,a7

\quit              ; Restaure les registres puis sortie.
                   movem.l (a7)+,d1-d4/a0
                   rts

;-------------------------------------------------
GetRectangle    ; a0 = adresse du sprite , D1 = X coin sup gauche, D2 = Y coin sup gauche,
 		;			   D3 = X coin inf droit,  D4 = Y coin inf droit,
 		move.l	a1,-(a7)
 		movea.l	BITMAP1(a0),a1
 		move.w	X(a0),d1
 		move.w	Y(a0),d2

 		move.w	WIDTH(a1),d3
 		move.w	HEIGHT(a1),d4

 		add.w	d1,d3
 		add.w	d2,d4
 		subq.w	#1,d3
 		subq.w	#1,d4
 		move.l	(a7)+,a1
 		rts

;-------------------------------------------------
MoveSpriteKeyboard						;a1 = adresse du sprite
		        movem.l	d1/d2,-(a7)
			clr.w	d1	;déplacement horizontal
			clr.w	d2	; déplacement vertical

\up			tst.b	UP_KEY
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

;----------------------------------------------

MoveSprite 	; a1 = adresse du sprite , d1 = déplacement horizontal	, d2 = déplacement vertical
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
\false 		; Si ca sort de l'écran, on ne modifie rien + Z = 0
 		andi.b #%11111011,ccr
\quit 		movem.l (a7)+,d1/d2/a0
 		rts
;----------------------------------------
IsOutOfX	move.l	d3,-(a7)			; a0 = adresse du bitmap , d1 = coordonnée x du pixel du début du bitmap
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
IsOutOfY	move.l	d3,-(a7)			; a0 = adresse du bitmap , d2 = coordonnée y du pixel du début du bitmap
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
IsOutOfScreen	jsr		IsOutOfX
		beq		\return_true
		jsr		IsOutOfY
		beq		\return_true
\return_false	andi.b	#%11111011,ccr
		rts
\return_true	ori.b	#%00000100,ccr
		rts

;-----------------------------------------
CopyLine	movem.l	d1/d2/d4/d5/a1,-(a7)       ; d0 = décallage en pixel , d3 = largeur de la ligne

		move.b	#8,d5
		sub.b	d0,d5
		clr.l	d1						; d1 = compteur de boucle
\loop		addq.l  #1,d1
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
PixelToByte	move.l	d2,-(a7)
		move.l	d3,d2
		lsr.l	#3,d3
		andi.l	#$00000007,d2
		beq		\mult_de8
		addq.l	#1,d3
\mult_de8	move.l	(a7)+,d2
		rts



;------------------------------------------
CopyBitmap	movem.l	d1/d2/d3/a0/a1,-(a7)
		move.w 	WIDTH(a0),d3 ; d3 = largeur du bitmap en pixel
		jsr		PixelToByte  ; d3 = largeur du bitmap en octet

 		move.w 	HEIGHT(a0),d1 ; D1 = hauteur du bitmap
 		clr.l	d2			  ; d2 servira de compteur de boucle

		lea		MATRIX(a0),a0 ; a0 pointe sur le premier octet du bitmap

\loop		addq.w	#1,d2
		jsr		CopyLine
		adda.l	#BYTE_PER_LINE,a1

		cmp.w	d2,d1
		bne		\loop
		movem.l	(a7)+,d1/d2/d3/a0/a1
		rts
;------------------------------------------------------------------------------
PixelToAdress	movem.l	d1/d2,-(a7)					; d1 = x abscisses du pixel  ,  d2 = y ordonnée du pixel
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
PrintBitmap	movem.l d0/a1,-(a7)
		jsr		PixelToAdress
		jsr		CopyBitmap
		movem.l (a7)+,d0/a1
		rts
;----------------------------------------------------------------------------
FillScreen	movem.l	a0/a1,-(a7)
		movea.l #VIDEO_BUFFER,a0
		movea.l	#VIDEO_BUFFER+VIDEO_SIZE,a1

\loop
 		move.l	d0,(a0)+
 		cmp.l	a1,a0
 		bne		\loop

 		movem.l	(a7)+,a0/a1
 		rts

;----------------------------------------------------------------------------
ClearScreen	move.l	d0,-(a7)
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
\loop		addq.l	#1,d0
		move.l	(a1),(a0)+
		move.l	#0,(a1)+
		cmp.l	d0,d1
		bne		\loop
		movem.l	(a7)+,d0/d1/a0/a1
		rts


;----------------------------------------------------------------------------
PrintSprite	movem.l	d0/d1/d2/a0,-(a7)
		move.w STATE(a1),d0 ; État de l'affichage -> D0.W
 		move.w X(a1),d1 ; X -> D1.W
 		move.w Y(a1),d2 ; Y -> D2.W
 		movea.l BITMAP1(a1),a0 ; Adresse du bitmap 1 -> A0.L

 		tst.w	d0
 		beq		\quit

 		jsr		PrintBitmap

\quit		movem.l	(a7)+,d0/d1/d2/a0
		rts
				

; ==============================
; Données
; ==============================
				org		$1000

InvaderA1_Bitmap dc.w 	24,16
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
 				
InvaderA2_Bitmap dc.w 24,16
                 dc.b %00000000,%11111111,%00000000
 		 dc.b %00000000,%11111111,%00000000
 		 dc.b %00111111,%11111111,%11111100
 		 dc.b %00111111,%11111111,%11111100
 		 dc.b %11111111,%11111111,%11111111
 		 dc.b %11111111,%11111111,%11111111
 		 dc.b %11111100,%00111100,%00111111
 		 dc.b %11111100,%00111100,%00111111
 		 dc.b %11111111,%11111111,%11111111
 		 dc.b %11111111,%11111111,%11111111
 		 dc.b %00001111,%11000011,%11110000
 		 dc.b %00001111,%11000011,%11110000
 		 dc.b %00111100,%00111100,%00111100
 		 dc.b %00111100,%00111100,%00111100
 		 dc.b %00001111,%00000000,%11110000
 		 dc.b %00001111,%00000000,%11110000

InvaderB1_Bitmap dc.w 	22,16							; Largeur, Hauteur
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
 				
InvaderB2_Bitmap dc.w 22,16
                 dc.b %00001100,%00000000,%11000000
 		 dc.b %00001100,%00000000,%11000000
 		 dc.b %00000011,%00000011,%00000000
 		 dc.b %00000011,%00000011,%00000000
 		 dc.b %11001111,%11111111,%11001100
 		 dc.b %11001111,%11111111,%11001100
 		 dc.b %11001100,%11111100,%11001100
 		 dc.b %11001100,%11111100,%11001100
 		 dc.b %00111111,%11111111,%11110000
 		 dc.b %00111111,%11111111,%11110000
 		 dc.b %00001111,%11111111,%11000000
 		 dc.b %00001111,%11111111,%11000000
 		 dc.b %00001100,%00000000,%11000000
 		 dc.b %00001100,%00000000,%11000000
 		 dc.b %00110000,%00000000,%00110000
 		 dc.b %00110000,%00000000,%00110000

InvaderC1_Bitmap dc.w 16,16
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

InvaderC2_Bitmap dc.w 16,16
 		 dc.w %0000001111000000
		 dc.w %0000001111000000
		 dc.w %0000111111110000
		 dc.w %0000111111110000
		 dc.w %0011111111111100
		 dc.w %0011111111111100
		 dc.w %1111001111001111
		 dc.w %1111001111001111
		 dc.w %1111111111111111
		 dc.w %1111111111111111
		 dc.w %0000110000110000
		 dc.w %0000110000110000
		 dc.w %0011001111001100
		 dc.w %0011001111001100
		 dc.w %1100110000110011
		 dc.w %1100110000110011

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

ShipShot_Bitmap dc.w 2,6
 		dc.b %11000000
 		dc.b %11000000
 		dc.b %11000000
 		dc.b %11000000
 		dc.b %11000000
 		dc.b %11000000

Invader 	dc.w SHOW ; Afficher le sprite
 		dc.w 0,152 ; X = 0, Y = 152
 		dc.l InvaderA1_Bitmap ; Bitmap à afficher
		dc.l 0 ; Inutilisé


Ship 		dc.w SHOW
 		dc.w (VIDEO_WIDTH-24)/2,VIDEO_HEIGHT-32
 		dc.l Ship_Bitmap
		dc.l 0

ShipShot 	dc.w HIDE
 		dc.w 0,0
 		dc.l ShipShot_Bitmap
		dc.l 0

InvaderX 		dc.w (VIDEO_WIDTH-(INVADER_PER_LINE*32))/2 ; Abscisse globale
InvaderY 		dc.w 32					   ; Ordonnée globale
InvaderCurrentStep      dc.w INVADER_STEP_X		           ; Pas en cours
InvaderCount            dc.w INVADER_COUNT

Invaders 		ds.b INVADER_COUNT*SIZE_OF_SPRITE

Cpt_MoveInvaders        dc.w 1