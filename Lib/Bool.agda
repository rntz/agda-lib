{-# OPTIONS --universe-polymorphism #-}

module Lib.Bool where

open import Lib.Level
open import Lib.Product
open import Lib.Sum
open import Lib.Imp

module BOOL where
 
   data Bool : Set where
      True : Bool
      False : Bool
   {-# COMPILED_DATA Bool Bool True False #-}
   {-# BUILTIN BOOL  Bool  #-}
   {-# BUILTIN TRUE  True  #-}
   {-# BUILTIN FALSE False #-}

   if_/_then_else : ∀{a} (P : Bool → Set a) (b : Bool) → P True → P False → P b
   if _ / True then b1 else b2 = b1
   if _ / False then b1 else b2 = b2

   _×b_ : Bool → Bool → Bool
   b1 ×b b2 = if const Bool / b1 then b2 else False

   _+b_ : Bool → Bool → Bool 
   b1 +b b2 = if const Bool / b1 then True else b2

   Check : Bool → Set
   Check True = Unit
   Check False = Void

open BOOL public 
   using (Bool ; True ; False ; if_/_then_else ; _×b_ ; _+b_ ; Check)