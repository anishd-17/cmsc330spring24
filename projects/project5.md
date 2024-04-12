# Project 5: MicroCaml Optimizer and Type Checker

> [!NOTE]
> **Due**: April 23rd, 2024, 11:59PM (Late: April 24th, 2024, 11:59PM) \
> **Points**: 50 public, 50 semipublic

## Introduction

In project 4, you implemented MicroCaml — a *dynamically-typed* version of OCaml with a subset of its features. In this project, you will implement:

* An **optimizer** for MicroCaml, which simplifies the MicroCaml AST using constant folding and constant propagation
* A **type checker** for MicroCaml, which verifies if a MicroCaml expression is well-typed before we run the code. If an expression passes the type checker, it will not cause type error when it runs.

## Part (A): AST optimization

In the first part of this project, you will implement a function `optimize : expr environment -> expr -> expr`,  which can partially evaluate and simplify the AST, using the following optimizations:

### Constant folding

Constant folding is the process of recognizing and evaluating constant expressions at compile time rather than computing them at runtime. Terms in constant expressions are typically simple literals, such as the integer literal 2, or boolean literal `true`, but they may also be variables whose values are known at compile time. Consider the expression:

  $$(3 + 4) * 6$$

Without an optimization, the expression `(3 + 4) * 6` will be calculated at run-time. We want to identify constructs such as these and substitute the computed values at compile time (in this case, `42`).

Constant folding can make use of arithmetic identities. For example:

* If `x` is numeric, the value of `0 * x` is zero, even if the compiler does not know the value of `x`.
* If `x` is numeric, the value of `1 * x` is `x`.

Note that there are more arithmetic identities you should implement. These are just a few!

### Constant propagation

Constant propagation is the process of substituting the values of known constants in expressions. In MicroCaml such constants include the int and boolean literals. Consider the following pseudocode:

```ocaml
 let x = 42 in 
    let y = 14 * 3 - x in 
    if y = 0 then 1 else 2
```
Propagating x yields: 
``` ocaml
let x = 42 in 
    let y = 0 in 
    if y = 0 then 1 else 2
```
Continuing to propagate yields `1` . 

You can assume all ASTs are well-typed and will not cause an error during the optimization.

Your optimizer should evaluate as much as possible. For many programs, it will be able to optimize the AST down
to just a single node containing the value returned after running the program.

### How is this optimization different from the evaluator in Project 4?

During evaluation, all variables are bound at some point (i.e. you can lookup the value of a variable in the environment). In the optimizer, variables may not be bound, but you'd still want to evaluate the expression as much as possible. For example, the optimizer will optimize `fun x-> 1+2+3+4+x` to `fun 10+x`, whereas the evaluator will evaluate it a closure with the body of the function unmodified.

### More examples of programs after optimization

```ocaml
optimize [] (parse_expr "fun x:Bool -> if x then 0 else 1") = Fun ("x", TBool, If (ID "x", Int 0, Int 1))

optimize [] (parse_expr "fun x:(Int -> Int) -> if true then (x 1) else 1") = Fun ("x", TArrow (TInt, TInt), App (ID "x", Int 1))

optimize [] (parse_expr "{a=100;b=200}.a") = Int 100

optimize [] (parse_expr "{a=100+200;b=200}") = Record [(Lab "a", Int 300); (Lab "b", Int 200)]

optimize [] (parse_expr ("0 * (1/0)")) 
(* Exception: DivByZeroError *)
```

## Part (B): Type Checker

The main purpose of a type system in a programming language is to reduce possibilities for bugs in the programs due to type errors. In this part of the project, you will implement a type checker for MicroCaml. In particular, you will implement a function, `typecheck`. It takes in a typing environment `exptype environment`, and an AST `expr` as arguments, and type checks the expression in the given environment, returning an `exptype` if the expression passes the type checker. It throws a type error if the expression does not type check. For example:
```ocaml
  typecheck [] (parse_expr "1 + 2") => TInt
  typecheck [] (parse_expr "2 >= 1") => TBool
  typecheck [] (parse_expr "1 + true") => (* Exception: TypeError *)
```

### AST

Below is the AST type `expr`, which is returned by the parser. We provided the lexer and parser generators (ocamllex, ocamlyacc) for this project. You can use your own parser from Project 4, but you will have to update it according to the new AST:
```ocaml
(* Binary operators *)
type op =
  | Add
  | Sub
  | Mult
  | Div
  | Concat
  | Greater
  | Less
  | GreaterEqual
  | LessEqual
  | Equal
  | NotEqual
  | Or
  | And

type var = string 
type label = Lab of var 

(* Types in MicroCaml *)
type exptype =
  | TInt
  | TBool
  | TArrow of exptype * exptype
  | TRec of (label * exptype) list

(* MicroCaml AST *)
type expr =
  | Int of int
  | Bool of bool
  | ID of var
  | Fun of var * exptype * expr
  | Not of expr
  | Binop of op * expr * expr
  | If of expr * expr * expr
  | App of expr * expr
  | Let of var * expr * expr
  | LetRec of var * exptype * expr * expr
  | Record of (label * expr) list
  | Select of label * expr
```

### Type Checking Rules
In this section, we provide the type checking rules for the MicroCaml. They are similar to the operational semantics inference rules and directly translates to typechecking code. 

$$ (var): \frac{\Gamma(x)=\tau}{\Gamma \vdash x:\tau } $$

$$ (Int): \frac{n \in Integer}{\Gamma \vdash n:Int } $$

Example: 
```ocaml
1
Type: TInt
```
$$ (Bool): \frac{b \in \{true, false\}}{\Gamma \vdash b:Bool } $$

Example: 
```ocaml
true
Type: TBool
```
 $$ (op:\space -,+,*,/): \frac{\Gamma \vdash e_1:Int, \Gamma\vdash e_2:Int}{\Gamma \vdash e_1\space op\space e_2:Int} $$

Example: 
```ocaml
1 + 2
Type: TInt
```

$$ (op:\space >, >=, <=, <): \frac{\Gamma \vdash e_1:Int, \Gamma\vdash e_2:Int}{\Gamma \vdash e_1\space op\space e_2:Bool} $$

Example: 
```ocaml
(1 > 3)
Type: TBool
```
$$ (op:\space =, !=): \frac{\Gamma \vdash e_1:\tau, \Gamma\vdash e_2:\tau}{\Gamma \vdash e_1\space op\space e_2:Bool} $$

Example: 
```ocaml
1 = 2
Type: TBool
```

$$ (op:\space ＆＆, || ): \frac{\Gamma \vdash e_1:Bool, \Gamma\vdash e_2:Bool}{\Gamma \vdash e_1\space op\space e_2:Bool} $$

Example: 
```ocaml
(1 = 2) || false 
Type: TBool
```
$$ (if): \frac{\Gamma \vdash e_1:Bool, \Gamma\vdash e_2:\tau,\Gamma\vdash e_2:\tau }{\Gamma \vdash if\space e_1\space then\space e_2\space else\space e_3:\tau} $$

Example:
```ocaml
let x = 3 in if not true then x > 3 else x < 3
Type: TBool
```

$$ (fun): \frac{\Gamma, x:\tau \vdash e:\tau'}{\Gamma \vdash (fun \space x:\tau \rightarrow e): \tau\rightarrow \tau'} $$

Example:
```ocaml
let rec f:(Int->Int) = fun x:Int -> x in f 1
Type: TInt
```
```ocaml
fun y:Int -> if y = 0 then y else 1
Type: TArrow (TInt, TInt)
```
```ocaml
(fun x:{l:Int} -> (x.l + 1))
 Type: TArrow (TRec [ (Lab "l", TInt) ], TInt)
```
$$ (app): \frac{\Gamma, e:\tau\rightarrow\tau', \Gamma\vdash e':\tau}{\Gamma \vdash e \space \space e':\tau'} $$

Example:
```ocaml
fun f:({x:Int; y:Int}->Int) -> f {x=5; y=6; z=3} + f {x=6; y=4}
Type: TArrow (TArrow (TRec [ (Lab "x", TInt); (Lab "y", TInt) ], TInt), TInt)
```


$$ (record): \frac{\Gamma\vdash e_1:\tau_1, \cdots \Gamma\vdash e_n:\tau_n}{\Gamma \vdash \{l_1=e_1; \cdots l_n=e_n\}: \{l_1:\tau_1; \cdots l_n:\tau_n\} }$$

Example:
```ocaml
{}
Type: TRec []
```
```ocaml
{x=10; y=20}
Type: TRec [(Lab "x", TInt); (Lab "y", TInt)]
```
$$ (select): \frac{\Gamma\vdash e_1:\tau_1, \cdots \Gamma e_n:\tau_n,  \Gamma \vdash \{l_1=e_1; \cdots l_n=e_n\}, \\ \Gamma\vdash \{l_1:\tau_1; \cdots l_n:\tau_n\} } {\Gamma\vdash\{l_1=e_1; \cdots l_n=e_n\}.l_x=\tau_x}$$

Example:
```ocaml
{x=10; y=20}.x
Type: TInt
```

$$ (not): \frac{\Gamma \vdash x:Bool}{\Gamma \vdash not \space x:Bool} $$

Example:
```ocaml
not ( 3 > 1)
Type: TBool
```

$$ (let): \frac{\Gamma\vdash e_1:\tau',\Gamma, x:\tau' \vdash e_2:\tau}{\Gamma\vdash (let\space x= e_1 \space in\space e_2):\tau } $$

Example:
```ocaml
let x = 2 * 3 + 4 in x - 5
Type = TInt
```
$$ (letrec): \frac{\Gamma\vdash e_1:\tau',\tau=\tau', \space\Gamma, x:\tau' \vdash e_2:\tau_2}{\Gamma\vdash (let\space rec \space x: \tau= e_1 \space in\space e_2):\tau_2 } $$

Example:
```ocaml
let rec fact:(Int->Int) = fun x:Int -> if x = 1 then 1 else x * fact (x - 1) in fact 3 
Type = TInt
```

### Subtyping
If `S` is a subtype of `T`, written S <: T,then an `S` can be used anywhere a `T` is expected. Subtyping is an essential feature of the object-oriented programming languages. In this project, we will explore the subtyping with functions and immutable records. You will implement a function `is_subtype : exptype -> exptype -> bool`, which takes two types `t1` and `t2` arguments, and returns `true` if `t1 <: t2`. 

Example:
```ocaml
(* Int <: Int *)
is_subtype (TInt) (TInt) = true
(* Int <: Bool *)
is_subtype (TInt) (TBool) = false
(* {a=100} <: {a:100} *)
is_subtype (TRec [(Lab "a", TInt)]) (TRec [(Lab "a", TInt)])  = true
(* {a=100;b=true} <: {a:100} *)
is_subtype (TRec [(Lab "a", TInt); (Lab "b", TBool)]) (TRec [(Lab "a", TInt)]) = true
```

#### Subtyping Rules
$$ (T-SUB): \frac{\Gamma\vdash e:S, \space S <:T}{\Gamma\vdash e:T } $$

$$ (S-REFL): {S <: S} $$
$$ (T-TRANS): \frac{S <: U, \space U <: T}{S <:T} $$

$$(S-RECWIDTH): \{l_i:T_i^{i \in 1..n+k}\} <: \{l_i:T_i^{i \in 1..n}\}$$

Examples:
```ocaml
{x:Int, y:Int} <: {x:Int}
{x:Int, y:Int, z:Bool} <: {x:Int}
```

$$(S-RECDEPTH): \frac{for\space each\space i\space \space S_i <: T_i}{\{l_i:T_i^{i \in 1..n}\} <: \{l_i:T_i^{i \in 1..n}\}} $$
Example:
```ocaml
{x:{a:Int, b:Int}, y:{m:Int}} <: {x:{a:Int},y:{}}
```
$$(S-PERM): \frac{\{k_j:S_j^{j\in1..n}\} \space is\space a\space permutation\space of\space \{l_i:T_i^{i\in1..n}\}}{\{k_j:S_j^{j\in1..n}\} <:\{l_i:T_i^{i\in1..n}\}} $$

Example:
```ocaml
{c:Unit,b:Bool,a:Int} <: {a:Int,b:Bool,c:Unit}
{a:Int,b:Bool,c:Unit} <: {c:Unit,b:Bool,a:Int}
```
$$(S-ARROW): \frac{T_1 <: S_1, \space S_2 <: T_2}{S_1\rightarrow S_2 <: T_1 \rightarrow T_2} $$
Example
```ocaml
(Animal → Cat) <: (Cat → Animal)
```

### Exceptions

We've kept the same list of possible error cases and exceptions from Project 4, but have adapted the cases to meet the new requirements for `optimize` and `typecheck`:

```ocaml
exception TypeError of string
exception DeclareError of string
exception SelectError of string
exception DivByZeroError
```

* A `TypeError` happens when the typechecker is unable to validate the type of the input.
* A `DeclareError` happens when the typechecker sees an ID that has not been declared.
* A `SelectError` happens when the typechecker is unable to select on a record when the key does not exist in the record.
* A `DivByZeroError` happens on attempted division by zero in the optimizer.

Note that we do not enforce what messages you use when raising a `TypeError` or `SelectError`. That's up to you.

### Ground Rules and Extra Info

In addition to all of the built in OCaml features and feature we've taught about in class, you may also use library functions found in the Stdlib module, and List module. You are free to define your own typing environment. 

### Testing & Submitting

Submit by running `submit` after pushing your code to GitHub. 

All tests will be run on direct calls to your code, comparing your return values to the expected return values. Any other output (e.g., for your own debugging) will be ignored. You will return `exception TypeError of string` if you detect a type error in the input AST. We recommend using relevant error messages when raising these exceptions in order to make debugging easier. We are not requiring intelligent messages that pinpoint an error to help a programmer debug, but as you do this project you might find you see where you could add those.

To test from the toplevel, run `dune utop src`. The necessary functions and types will automatically be imported for you.

## Academic Integrity

Please **carefully read** the academic honesty section of the course syllabus. **Any evidence** of impermissible cooperation on projects, use of disallowed materials or resources, or unauthorized use of computer accounts, **will be** submitted to the Student Honor Council, which could result in an XF for the course, or suspension or expulsion from the University. This includes posting this project to GitHub after the course is over. Be sure you understand what you are and what you are not permitted to do in regards to academic integrity when it comes to project assignments. These policies apply to all students, and the Student Honor Council does not consider lack of knowledge of the policies to be a defense for violating them. Full information is found in the course syllabus, which you should review before starting.