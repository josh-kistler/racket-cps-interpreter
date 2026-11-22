# Racket CPS Interpreter

A small functional-language interpreter implemented in **Racket** using **continuation-passing style (CPS)**.

The project models evaluation explicitly through lexical environments, closures, and continuation structures rather than relying solely on Racket's implicit call stack. Variables are represented using **De Bruijn indices**, and the language supports first-class continuation capture and nonlocal control flow.

## Features

- Continuation-passing style evaluation
- Explicit lexical environments
- De Bruijn-indexed variables
- First-class functions and lexical closures
- Local variable bindings
- Arithmetic and conditional expressions
- Explicit continuation representations
- First-class continuation capture and invocation
- Nonlocal control flow
- Native Racket continuation handling with `let/cc`

## Supported Language Constructs

The interpreter supports the following expression forms:

| Construct | Purpose |
| --- | --- |
| `const` | Numeric or Boolean constants |
| `dBvar` | Variables represented by De Bruijn indices |
| `mult` | Multiplication |
| `decr` | Decrement by one |
| `zerop` | Zero test |
| `dBlam` | Lambda abstraction |
| `app` | Function application |
| `dBlocal` | Local binding |
| `ifte` | Conditional expression |
| `dBcatch` | Capture the current continuation |
| `throw` | Transfer control to a captured continuation |

## Architecture

### Abstract Syntax

Programs are represented directly as Racket structures rather than parsed from textual source code.

For example:

```racket
(mult
  (const 3)
  (decr (const 6)))
```

represents the equivalent of:

```text
3 * (6 - 1)
```

### Environments

Lexical bindings are represented using explicit environment structures:

```racket
(struct empty-env () #:transparent)
(struct extend-env (a env) #:transparent)
```

Variables use **De Bruijn indices** rather than names. Index `0` refers to the most recently introduced binding, while larger indices walk outward through enclosing environments.

Environment lookup is handled by `apply-env`.

### Closures

Lambda expressions evaluate to lexical closures:

```racket
(struct clos-lam (body env) #:transparent)
```

Each closure stores both its function body and the environment in which the function was created. This preserves lexical scope when the function is later applied.

### Explicit Continuations

Instead of allowing intermediate evaluation state to exist only on Racket's call stack, the interpreter represents the remaining computation explicitly.

Continuation structures include states for:

- multiplication
- decrement
- zero testing
- conditionals
- function application
- local bindings
- continuation invocation

`apply-k` dispatches on these structures and determines what computation should happen after a value has been produced.

### CPS Evaluator

The main evaluator is:

```racket
(value-of-cps expression environment continuation)
```

Every expression is evaluated relative to an explicit environment and continuation.

Instead of directly returning intermediate results, evaluation passes values into the current continuation.

For example:

```racket
(value-of-cps
  (mult (const 3) (decr (const 6)))
  (empty-env)
  (empty-k))
```

evaluates to:

```text
15
```

## First-Class Continuations

The language supports capturing and invoking continuations through `dBcatch` and `throw`.

`dBcatch` captures the current continuation and inserts it into the lexical environment as a first-class value.

For example:

```racket
(value-of-cps
  (dBcatch
    (throw (dBvar 0) (const 42)))
  (empty-env)
  (empty-k))
```

evaluates to:

```text
42
```

When `throw` invokes a captured continuation, the continuation associated with the `throw` expression itself is bypassed, allowing nonlocal transfer of control.

## Native Continuation Example

The project also implements:

```racket
(last-non-zero ls)
```

using Racket's native `let/cc` continuation mechanism.

The function returns the portion of a list following its final zero:

```racket
(last-non-zero '(1 0 2 0 5 6))
```

returns:

```racket
'(5 6)
```

If the list contains no zero, the original list is returned.

## Technologies and Concepts

- Racket
- Functional programming
- Continuation-passing style
- Interpreters
- Abstract syntax trees
- Lexical scoping
- Closures
- De Bruijn indices
- First-class continuations
- Pattern matching
- Nonlocal control flow

## Running the Project

Install [Racket](https://racket-lang.org/) and run:

```bash
racket cps-interpreter.rkt
```

The interpreter can also be loaded into DrRacket for interactive evaluation and experimentation.

## What This Project Demonstrates

This project explores implementation techniques used in programming-language runtimes and interpreters. In particular, it demonstrates how environments, closures, evaluation order, and control flow can be represented explicitly rather than being delegated entirely to the host language's runtime.
