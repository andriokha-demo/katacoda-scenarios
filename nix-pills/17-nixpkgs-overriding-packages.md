# Nixpkgs Overriding Packages

Welcome to the 17th Nix pill. In the previous
[16th](#nixpkgs-parameters) pill we have started to dive into the
[nixpkgs repository](http://github.com/NixOS/nixpkgs). `Nixpkgs` is a
function, and we've looked at some parameters like `system` and
`config`.

Today we'll talk about a special attribute: `config.packageOverrides`.
Overriding packages in a set with fixed point can be considered another
design pattern in nixpkgs.

## Overriding a package

Recall the override design pattern from the [nix pill
14](#override-design-pattern). Instead of calling a function with
parameters directly, we make the call (function + parameters)
overridable.

We put the override function in the returned attribute set of the
original function call.

Take for example graphviz. It has an input parameter xorg. If it's null,
then graphviz will build without X support.

This will build graphviz without X support, it's as simple as that.

However let's say a package `P` depends on graphviz, how do we make `P`
depend on the new graphviz without X support?

## In an imperative world...

...you could do something like this:

Given `pkgs.P` depends on `pkgs.graphviz`, it's easy to build `P` with
the replaced graphviz. On a pure functional language it's not that easy
because you can assign to variables only once.

## Fixed point

The fixed point with lazy evaluation is crippling but about necessary in
a language like Nix. It lets us achieve something similar to what we'd
do imperatively.

Follows the definition of fixed point in
[nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/lib/trivial.nix#L21):

It's a function that accepts a function `f`, calls `f result` on the
result just returned by `f result` and returns it. In other words it's
`f(f(f(....`

At first sight, it's an infinite loop. With lazy evaluation it isn't,
because the call is done only when needed.

Without the `rec` keyword, we were able to refer to `a` and `b` of the
same set.

-   First `pkgs` gets called with an unevaluated thunk `(pkgs(pkgs(...)`

-   To set the value of `c` then `self.a` and `self.b` are evaluated.

-   The `pkgs` function gets called again to get the value of `a` and
    `b`.

The trick is that `c` is not needed to be evaluated in the inner call,
thus it doesn't go in an infinite loop.

Won't go further with the explanation here. A good post about fixed
point and Nix can be [found
here](http://r6.ca/blog/20140422T142911Z.html).

### Overriding a set with fixed point

Given that `self.a` and `self.b` refer to the passed set and not to the
literal set in the function, we're able to override both `a` and `b` and
get a new value for `c`:

In the first case we computed pkgs with the overrides, in the second
case we also included the overriden attributes in the result.

## Overriding nixpkgs packages

We've seen how to override attributes in a set such that they get
recursively picked by dependant attributes. This approach can be used
for derivations too, after all `nixpkgs` is a giant set of attributes
that depend on each other.

To do this, `nixpkgs` offers `config.packageOverrides`. So `nixpkgs`
returns a fixed point of the package set, and `packageOverrides` is used
to inject the overrides.

Create a `config.nix` file like this somewhere:

Now we can build e.g. asciidocFull and it will automatically use the
overridden graphviz:

Note how we pass the `config` with `packageOverrides` when importing
`nixpkgs`. Then `pkgs.asciidocFull` is a derivation that has graphviz
input (`pkgs.asciidoc` is the lighter version and doesn't use graphviz
at all).

Since there's no version of asciidoc with graphviz without X support in
the binary cache, Nix will recompile the needed stuff for you.

## The \~/.nixpkgs/config.nix file

In the previous pill we already talked about this file. The above
`config.nix` that we just wrote could be the content of
`~/.nixpkgs/config.nix`.

Instead of passing it explicitly whenever we import `nixpkgs`, it will
be automatically [imported by
nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/all-packages.nix#L54).

## Conclusion

We've learned about a new design pattern: using fixed point for
overriding packages in a package set.

Whereas in an imperative setting, like with other package managers, a
library is installed replacing the old version and applications will use
it, in Nix it's not that straight and simple. But it's more precise.

Nix applications will depend on specific versions of libraries, hence
the reason why we have to recompile asciidoc to use the new graphviz
library.

The newly built asciidoc will depend on the new graphviz, and old
asciidoc will keep using the old graphviz undisturbed.

## Next pill

...we will stop diving `nixpkgs` for a moment and talk about store
paths. How does Nix compute the path in the store where to place the
result of builds? How to add files to the store for which we have an
integrity hash?
