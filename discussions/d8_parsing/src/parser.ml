open Lexer

(* Types *)
type expr =
| Int of int
| Plus of expr * expr
| Mult of expr * expr

(* Provided helper function - takes a token list and an exprected token.
 * Handles error cases and returns the tail of the list *)
let match_token (toks : token list) (tok : token) : token list =
  match toks with
  | [] -> raise (Failure(string_of_token tok))
  | h::t when h = tok -> t
  | h::_ -> raise (Failure(
      Printf.sprintf "Expected %s from input %s, got %s"
        (string_of_token tok)
        (string_of_list string_of_token toks)
        (string_of_token h)
    ))

let lookahead toks = match toks with
	 h::t -> h
	| _ -> raise (Failure("Empty input to lookahead"))



(* Parses a token list. *)
let rec parser (toks : token list) : expr =
  let t1, e1 = parse_S toks in 
  match t1 with 
  | [Tok_EOF] -> e1 
  | _ -> failwith "error"

(* Parses the S rule. *)
and parse_S (toks : token list) : (token list * expr) =
  let (t1, e1) = parse_M toks in 
  match lookahead t1 with 
  | Tok_Plus -> let t2 = match_token t1 Tok_Plus in 
                let t3, e2 = parse_S t2 in 
                (t3, Plus(e1, e2))
  | _ -> (t1, e1)

(* Parses the M rule. *)
and parse_M (toks : token list) : (token list * expr) =
  let (t1, e1) = parse_N toks in 
  match lookahead t1 with 
  | Tok_Mult -> let t2 = match_token t1 Tok_Mult in 
                let t3, e2 = parse_M t2 in 
                (t3, Mult (e1, e2))
  | _ -> (t1, e1)

            
(* Parses the N rule. *)
and parse_N (toks : token list) : (token list * expr) =
  match lookahead toks with 
  | Tok_Int n -> let t1 = match_token toks (Tok_Int n) in 
                 (t1, Int (n)) 
  | Tok_LParen -> let t2 = match_token toks Tok_LParen in 
                  let (t3, e1) = parse_S t2 in 
                  let t4 = match_token t3 Tok_RParen in 
                  (t4, e1)
  | _ -> failwith "error"