
open import Prelude hiding (⊥)
open import Accessibility.Inductive
open import Accessibility.IndexedList
open import FocusedCPL.Core 
open import FocusedCPL.Weakening

module FocusedCPL.Evidence where

module EVIDENCE (UWF : UpwardsWellFounded) 
  (dec≺ : (w w' : _) → Decidable (TRANS-UWF._≺*_ UWF w w')) where

  open TRANS-UWF UWF
  open ILIST UWF
  open SEQUENT UWF
  open WEAKENING UWF

  data Atomic (א : FCtx) (Γ : MCtx) (wc : W) : Type ⁻ → Bool → Set where
    ↓E : ∀{A b}
      (x : ↓ A at wc ∈ Γ)
      → Atomic א Γ wc A b
    Cut : ∀{A} 
      (N : Term א Γ wc · (Reg A)) 
      → Atomic א Γ wc A True
    ⊃E : ∀{A B b}
      (R : Atomic א Γ wc (A ⊃ B) b)
      (V : Value א Γ wc A)
      → Atomic א Γ wc B b

  -- The boolean flag is a graceless mechanism, but the point is that, if you 
  -- commit yourself to not using cut, there's a trivial "unwind" 

  unwind : ∀{א Γ A U w wc}
    → U stable⁻
    → wc ≺* w
    → Atomic א Γ w A False
    → Spine א Γ w A wc U
    → Term א Γ wc · U
  unwind pf ω (↓E x) Sp = ↓L pf ω x Sp
  unwind pf ω (⊃E R V) Sp = unwind pf ω R (⊃L V Sp) 

  data EvidenceA (Γ : MCtx) (wc : W) : Type ⁻ → W → Bool → Set where
    E≡ : ∀{A b} → EvidenceA Γ wc A wc b
    E+ : ∀{A w b}
      (ω : wc ≺+ w) 
      (R : Atomic [] Γ w A b)
      → EvidenceA Γ wc A w b

  data EvidenceΩ (Γ : MCtx) (wc : W) : ICtx → Bool → Set where
    ·t : EvidenceΩ Γ wc · True
    ·f : EvidenceΩ Γ wc · False
    I≡ : ∀{A b} → EvidenceΩ Γ wc (I A wc) b
    I+ : ∀{A w b}
      (ω : wc ≺+ w) 
      (R : Atomic [] Γ w (↑ A) b)
      → EvidenceΩ Γ wc (I A w) b

  varE : ∀{A Γ w wc b} → (↓ A at w) ∈ Γ → wc ≺* w → EvidenceA Γ wc A w b
  varE x ≺*≡ = E≡
  varE x (≺*+ ω) = E+ ω (↓E x)

  cutE : ∀{A Γ w wc} → Term [] Γ w · (Reg A) → wc ≺* w 
    → EvidenceA Γ wc A w True
  cutE N ≺*≡ = E≡
  cutE N (≺*+ ω) = E+ ω (Cut N)

  atmE : ∀{A Γ w wc b} → EvidenceA Γ wc (↑ A) w b → EvidenceΩ Γ wc (I A w) b
  atmE E≡ = I≡
  atmE (E+ ω R) = I+ ω R 

  appE : ∀{A Γ w wc B b} 
    → EvidenceA Γ wc (A ⊃ B) w b
    → Value [] Γ w A
    → EvidenceA Γ wc B w b
  appE E≡ V = E≡
  appE (E+ ω R) V = E+ ω (⊃E R V)

  evidenceΩ≺ : ∀{w Γ Ω b} 
    → EvidenceΩ Γ w Ω b
    → w ≺' Ω 
  evidenceΩ≺ ·t = ·
  evidenceΩ≺ ·f = ·
  evidenceΩ≺ I≡ = I ≺*≡
  evidenceΩ≺ (I+ ω R) = I (≺*+ ω)

  evidenceA≺ : ∀{w w' Γ A b}
    → EvidenceA Γ w A w' b
    → w ≺* w'
  evidenceA≺ E≡ = ≺*≡
  evidenceA≺ (E+ ω R) = ≺*+ ω


  data Evidence (Γ : MCtx) (wc : W) : MCtx → Item (Type ⁺) → Set where
    N⊀ : ∀{w A} → 
      (ω : wc ≺+ w → Void)
      → Evidence Γ wc [] (A at w)      
    N+ : ∀{w A b} → 
      (ω : wc ≺+ w)
      (R : Atomic [] Γ w (↑ A) b)
      → Evidence Γ wc [] (A at w)
    C⊀ : ∀{w A Γ' Item}
      (ω : wc ≺+ w → Void)
      (edΓ : Evidence Γ wc Γ' Item) 
      → Evidence Γ wc ((A at w) :: Γ') Item
    C+ : ∀{w A Γ' Item b}
      (ω : wc ≺+ w)
      (R : Atomic [] (Γ' ++ Γ) w (↑ A) b)
      (edΓ : Evidence Γ wc Γ' Item) 
      → Evidence Γ wc ((A at w) :: Γ') Item

  ed≺ : ∀{w w' Γ Γ' Item} 
    → w ≺ w'
    → Evidence Γ w Γ' Item 
    → Evidence Γ w' Γ' Item
  ed≺ ω (N⊀ ω') = N⊀ (ω' o ≺+S ω)
  ed≺ {w} {w'} ω (N+ {wn} _ R) with dec≺ w' wn
  ed≺ ω (N+ _ R) | Inl ≺*≡ = N⊀ (nrefl+ _ _ refl)
  ... | Inl (≺*+ ω') = N+ ω' R
  ... | Inr ω' = N⊀ (ω' o ≺*+)
  ed≺ ω (C⊀ ω' edΓ) = C⊀ (ω' o ≺+S ω) (ed≺ ω edΓ)
  ed≺ {w} {w'} ω (C+ {wn} _ R edΓ) with dec≺ w' wn
  ed≺ ω (C+ ω' R edΓ) | Inl ≺*≡ = C⊀ (nrefl+ _ _ refl) (ed≺ ω edΓ)
  ... | Inl (≺*+ ω') = C+ ω' R (ed≺ ω edΓ)
  ... | Inr ω' = C⊀ (ω' o ≺*+) (ed≺ ω edΓ)

  ed≺+ : ∀{w w' Γ Γ' Item} 
    → w ≺+ w'
    → Evidence Γ w Γ' Item 
    → Evidence Γ w' Γ' Item
  ed≺+ (≺+0 ω) edΓ = ed≺ ω edΓ
  ed≺+ (≺+S ω ω') edΓ = ed≺+ ω' (ed≺ ω edΓ) 

  ed≺* : ∀{w w' Γ Γ' Item} 
    → w ≺* w'
    → Evidence Γ w Γ' Item 
    → Evidence Γ w' Γ' Item
  ed≺* ≺*≡ edΓ = edΓ
  ed≺* (≺*+ ω) edΓ = ed≺+ ω edΓ

  postulate XXX-HOLE : {A : Set} → String → A

  sub-append-swap : {A : Set} 
    (xs ys zs : List A)
    → LIST.SET.Sub (xs ++ (ys ++ zs)) (ys ++ (xs ++ zs))
  sub-append-swap xs ys zs n with LIST.split-append {xs = xs} n
  ... | Inl n' = LIST.SET.sub-appendl (xs ++ zs) ys
                   (LIST.SET.sub-appendr xs zs n')
  ... | Inr n' with LIST.split-append {xs = ys} n' 
  ... | Inl n'' = LIST.SET.sub-appendr ys (xs ++ zs) n''
  ... | Inr n'' = LIST.SET.sub-appendl (xs ++ zs) ys
                    (LIST.SET.sub-appendl zs xs n'')

{-
  sub-append-swap₂ : {A : Set} → ∀{zs y} 
    (xs : List A)
    → LIST.SET.Sub (xs ++ (y :: zs)) (y :: (xs ++ zs))
  sub-append-swap₁ [] ys n = n
  sub-append-swap₁ xs [] n = n
  sub-append-swap₁ xs (x :: ys) n = 
    S (sub-append-swap₁ xs ys {!!}) -}

{-
  deN : ∀{Γ A w wc C}
    → EvidenceΩ Γ wc (I A w)
    → Term [] ((A at w) :: Γ) wc · C
    → Term [] Γ wc · C
  deN I≡ N = {!!}
  deN (I+ ω R) N = {!!}
-}

  edV : ∀{Γ' Γ A wc w C}
    → Evidence Γ wc Γ' (A at w) 
    → Value [] (Γ' ++ Γ) wc C
    → Value [] (Γ' ++ (A at w) :: Γ) wc C

  edN : ∀{Γ' Γ A Ω wc w C b} 
    → Evidence Γ wc Γ' (A at w) 
    → EvidenceΩ (Γ' ++ Γ) wc Ω b
    → Term [] (Γ' ++ Γ) wc Ω (Reg C)
    → Term [] (Γ' ++ (A at w) :: Γ) wc Ω (Reg C)
 
  edSp : ∀{Γ' Γ A B C wc wh w b}
    → Evidence Γ wc Γ' (A at w) 
    → EvidenceA (Γ' ++ Γ) wc B wh b
    → Spine [] (Γ' ++ Γ) wh B wc (Reg C)
    → Spine [] (Γ' ++ (A at w) :: Γ) wh B wc (Reg C)

  edV {Γ'} edΓ (pR x) = pR (LIST.SET.sub-append-congr Γ' LIST.SET.sub-wken x)
  edV edΓ (↓R N₁) = ↓R (edN edΓ ·t N₁)
  edV edΓ (◇R ω N₁) = ◇R ω (edN (ed≺ ω edΓ) ·t N₁)
  edV edΓ (□R N₁) = □R λ ω → edN (ed≺ ω edΓ) ·t (N₁ ω)

  edN edΓ I≡ (L pf⁺ N₁) = L pf⁺ (edN (C⊀ (nrefl+ _ _ refl) edΓ) ·t N₁)
  edN edΓ (I+ ω R) (L pf⁺ N₁) = L pf⁺ (edN (C+ ω R edΓ) ·t N₁)
  edN {Γ'} edΓ ed (↓L pf⁻ ωh x Sp) = 
    ↓L pf⁻ ωh (LIST.SET.sub-append-congr Γ' LIST.SET.sub-wken x) 
      (edSp edΓ (varE {b = True} x ωh) Sp)
  edN edΓ ed ⊥L = ⊥L
  edN edΓ ed (◇L N₁) = 
    ◇L λ ω N₀ → edN edΓ ·t (N₁ ω {! XXX-HOLE "I BELIEVE I CAN DO THIS" !})
  edN edΓ ed (□L N₁) = 
    □L λ N₀ → edN edΓ ·t (N₁ λ ω → XXX-HOLE "I BELIEVE I CAN DO THIS")
  edN edΓ ed (↑R V₁) = ↑R (edV edΓ V₁)
  edN edΓ ed (⊃R N₁) = ⊃R (edN {b = True} edΓ I≡ N₁) 

  edSp edΓ ed pL = pL
  edSp edΓ ed (↑L N₁) = ↑L (edN edΓ (atmE ed) N₁)
  edSp edΓ ed (⊃L V₁ Sp₂) = 
    ⊃L (edV (ed≺* (evidenceA≺ ed) edΓ) V₁) (edSp edΓ (appE ed V₁) Sp₂)

  ed-wkN₁ : ∀{w wh wc Γ C b} {B : Type ⁺}
    → wc ≺* w
    → EvidenceΩ Γ wc (I B wh) b
    → Term [] Γ w · (Reg C)
    → Term [] ((B at wh) :: Γ) w · (Reg C)
  ed-wkN₁ {w} {wh} ω ed N with dec≺ w wh 
  ed-wkN₁ ω ed N | Inr ωh =
    wkN <> (⊆to/wkenirrev ωh (⊆to/refl _)) · N
  ed-wkN₁ ω ed N | Inl ≺*≡ = 
    wkN <> (⊆to/wken (⊆to/refl _)) · N
  ed-wkN₁ ω I≡ N | Inl (≺*+ ωh) = abort (≺+⊀ ωh ω)
  ed-wkN₁ ω (I+ _ R) N | Inl (≺*+ ωh) = edN (N+ ωh R) ·t N

  decut : ∀{w w' Γ A B}
    (Γ' : MCtx)
    → Term [] (Γ' ++ Γ) w · (Reg A)
    → Term [] (Γ' ++ Γ) w' · (Reg B)
    → Term [] (Γ' ++ (↓ A at w) :: Γ) w' · (Reg B)
  decut {w} {w'} Γ' N N₀ with dec≺ w' w
  decut Γ' N N₀ | Inr ω = 
    wkN <> 
      (⊆to/trans (⊆to/wkenirrev ω (⊆to/refl _)) 
        (⊆to/equiv (sub-append-swap [ _ ] Γ' _) (sub-append-swap Γ' [ _ ] _))) 
      · N₀
  decut Γ' N N₀ | Inl ≺*≡ = 
    wkN <> 
      (⊆to/trans (⊆to/wken (⊆to/refl _)) 
        (⊆to/equiv (sub-append-swap [ _ ] Γ' _) (sub-append-swap Γ' [ _ ] _))) 
      · N₀
  decut Γ' N N₀ | Inl (≺*+ ω) = 
    wkN <> 
      (⊆to/equiv (sub-append-swap [ _ ] Γ' _) (sub-append-swap Γ' [ _ ] _))
      · (edN (N+ ω (Cut (↑R (↓R N)))) ·t N₀)



{-
with dec≺ w wh
  ed-wkN₂ ω (I+ ω' R) N | Inr ωh =  "WHOO"
  ed-wkN₂ ω (I+ ω' R) N | Inl ωh =  "WHOO" -}

  
--  Evidence Γ :
{-
  edN : 
    → (Γ' : Ctx)
    → 
-}

{-
with dec≺ w wh 
  ed-wkN₂ ω ed ed' N | Inr ωh =
    wkN <> (⊆to/wkenirrev ωh (⊆to/refl _)) (evidence≺ ed') N
  ed-wkN₂ ω ed ed' N | Inl ≺*≡ = 
    wkN <> (⊆to/wken (⊆to/refl _)) (evidence≺ ed') N
  ed-wkN₂ ω I≡ ed' N | Inl (≺*+ ωh) = abort (≺+⊀ ωh ω)
  ed-wkN₂ ω (I+ _ R) ed' N | Inl (≺*+ ωh) = 
-}
  -- Note - we can now prove this after cut.

{-
  ed-wkN+ : ∀{Γ Ω wc w A C} (Γ' : MCtx)
    → wc ≺+ w
    → Atomic [] Γ w (↑ A)
    → Term [] (Γ' ++ Γ) wc Ω (Reg C)
    → wc ≺' Ω
    → Term [] (Γ' ++ (A at w) :: Γ) wc Ω (Reg C)  

  ed-wkN+ ω R N = {!N!}

  ed-wkN : ∀{Γ Ω wc w A C} (Γ' : MCtx)
    → EvidenceΩ Γ wc (I A w)
    → Term [] (Γ' ++ Γ) wc Ω (Reg C)
    → wc ≺' Ω
    → Term [] (Γ' ++ (A at w) :: Γ) wc Ω (Reg C)  
  ed-wkN Γ' I≡ N ed =
    wkN <> (⊆to/append-congr Γ' (⊆to/wken (⊆to/refl _))) ed N
  ed-wkN Γ' (I+ ω R) N ed = {!!}
-}