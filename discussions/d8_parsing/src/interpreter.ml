open Parser

(* Evaluater *)

let rec eval (ast : expr) : int =
  match ast with 
  | Int n -> n 
  | Mult (e1, e2) -> (eval e1) * (eval e2) 
  | Plus (e1, e2) -> (eval e1) + (eval e2)