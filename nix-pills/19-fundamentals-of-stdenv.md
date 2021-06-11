# Fundamentals of Stdenv

Welcome to the 19th Nix pill. In the previous [18th](#nix-store-paths)
pill we did dive into the algorithm used by Nix to compute the store
paths, and also introduced fixed-output store paths.

This time we will instead look into `nixpkgs`, in particular one of its
core derivation: `stdenv`.

The `stdenv` is not a special derivation to Nix, but it's very important
for the `nixpkgs` repository. It serves as base for packaging software.
It is used to pull in dependencies such as the GCC toolchain, GNU make,
core utilities, patch and diff utilities, and so on. Basic tools needed
to compile a huge pile of software currently present in `nixpkgs`.

## What is stdenv

First of all `stdenv` is a derivation. And it's a very simple one:

It has just two files: `/setup` and
`/nix-support/propagated-user-env-packages`. Don't care about the
latter; it's empty, in fact. The important file is `/setup`.

How can this simple derivation pull in all the toolchain and basic tools
needed to compile packages? Let's look at the runtime dependencies:

How can it be? The package must be referring to those package somehow.
In fact, they are hardcoded in the `/setup` file:

## The setup file

Remember our generic `builder.sh` in [Pill 8](#generic-builders)? It
sets up a basic `PATH`, unpacks the source and runs the usual autotools
commands for us.

The `stdenv` `setup` file is exactly that. It sets up several
environment variables like `PATH` and creates some helper bash functions
to build a package. I invite you to read it, it's only 860 lines at the
time of this writing.

The hardcoded toolchain and utilities are used to initially fill up the
environment variables so that it's more pleasant to run common commands,
similar to what we did with our builder with `baseInputs` and
`buildInputs`.

The build with `stdenv` works in phases. Phases are like `unpackPhase`,
`configurePhase`, `buildPhase`, `checkPhase`, `installPhase`,
`fixupPhase`. You can see the default list in the `genericBuild`
function.

What `genericBuild` does is just run these phases. Default phases are
just bash functions, you can easily read them.

Every phase has hooks to run commands before and after the phase has
been executed. Phases can be overwritten, reordered, whatever, it's just
bash code.

How to use this file? Like our old builder. To test it, we enter a fake
empty derivation, source the `stdenv` `setup`, unpack the hello sources
and build it:

*I unset `PATH` to further show that the `stdenv` is enough
self-contained to build autotools packages that have no other
dependencies.*

So we ran the `configurePhase` function and `buildPhase` function and
they worked. These bash functions should be self-explanatory, you can
read the code in the `setup` file.

## How is the setup file built

Until now we worked with plain bash scripts. What about the Nix side?
The `nixpkgs` repository offers a useful function, like we did with our
old builder. It is a wrapper around the raw derivation function which
pulls in the `stdenv` for us, and runs `genericBuild`. It's
`stdenv.mkDerivation`.

Note how `stdenv` is a derivation but it's also an attribute set which
contains some other attributes, like `mkDerivation`. Nothing fancy here,
just convenience.

Let's write a `hello.nix` expression using this new discovered `stdenv`:

Don't be scared by the `with` expression. It pulls the `nixpkgs`
repository into scope, so we can directly use `stdenv`. It looks very
similar to the hello expression in [Pill 8](#generic-builders).

It builds, and runs fine:

## The stdenv.mkDerivation builder

Let's take a look at the builder used by `mkDerivation`. You can read
the code [here in
nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/make-derivation.nix):

Also take a look at our old derivation wrapper in previous pills! The
builder is bash (that shell variable), the argument to the builder
(bash) is `default-builder.sh`, and then we add the environment variable
`$stdenv` in the derivation which is the `stdenv` derivation.

You can open
[default-builder.sh](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/default-builder.sh)
and see what it does:

It's what we did in [Pill 10](#developing-with-nix-shell) to make the
derivations `nix-shell` friendly. When entering the shell, the setup
file only sets up the environment without building anything. When doing
`nix-build`, it actually runs the build process.

To get a clear understanding of the environment variables, look at the
.drv of the hello derivation:

So short I decided to paste it entirely above. The builder is bash, with
`-e default-builder.sh` arguments. Then you can see the `src` and
`stdenv` environment variables.

Last bit, the `unpackPhase` in the setup is used to unpack the sources
and enter the directory, again like we did in our old builder.

## Conclusion

The `stdenv` is the core of the `nixpkgs` repository. All packages use
the `stdenv.mkDerivation` wrapper instead of the raw derivation. It does
a bunch of operations for us and also sets up a pleasant build
environment.

The overall process is simple:

-   `nix-build`

-   `bash -e default-builder.sh`

-   `source $stdenv/setup`

-   `genericBuild`

That's it, everything you need to know about the stdenv phases is in the
[setup
file](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/setup.sh).

Really, take your time to read that file. Don't forget that juicy docs
are also available in the [nixpkgs
manual](http://nixos.org/nixpkgs/manual/#chap-stdenv).

## Next pill...

...we will talk about how to add dependencies to our packages with
`buildInputs` and `propagatedBuildInputs`, and influence downstream
builds with setup hooks and env hooks. These concepts are crucial to how
`nixpkgs` packages are composed.
