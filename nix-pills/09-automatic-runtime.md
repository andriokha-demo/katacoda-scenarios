# Automatic Runtime Dependencies

Welcome to the 9th Nix pill. In the previous [8th
pill](#generic-builders) we wrote a generic builder for autotools
projects. We feed build dependencies, a source tarball, and we get a Nix
derivation as a result.

Today we stop by the GNU hello world program to analyze build and
runtime dependencies, and enhance the builder in order to avoid
unnecessary runtime dependencies.

## Build dependencies

Let's start analyzing build dependencies for our GNU hello world
package:

It has exactly the derivations referenced in the `derivation` function,
nothing more, nothing less. Some of them might not be used at all,
however given that our generic mkDerivation function always pulls such
dependencies (think of it like
[build-essential](https://packages.debian.org/unstable/build-essential)
of Debian), for every package you build from now on, you will have these
packages in the nix store.

Why are we looking at .drv files? Because the hello.drv file is the
representation of the build action to perform in order to build the
hello out path, and as such it also contains the input derivations
needed to be built before building hello.

## Digression about NAR files

NAR is the Nix ARchive. First question: why not tar? Why another
archiver? Because commonly used archivers are not deterministic. They
add padding, they do not sort files, they add timestamps, etc.. Hence
NAR, a very simple deterministic archive format being used by Nix for
deployment. NARs are also used extensively within Nix itself as we'll
see below.

For the rationale and implementation details you can find more in the
[Dolstra's PhD Thesis](http://nixos.org/~eelco/pubs/phd-thesis.pdf).

To create NAR archives, it's possible to use `nix-store --dump` and
`nix-store --restore`. Those two commands work regardless of
`/nix/store`.

## Runtime dependencies

Something is different for runtime dependencies however. Build
dependencies are automatically recognized by Nix once they are used in
any `derivation` call, but we never specify what are the runtime
dependencies for a derivation.

There's really black magic involved. It's something that at first glance
makes you think "no, this can't work in the long term", but at the same
time it works so well that a whole operating system is built on top of
this magic.

In other words, Nix automatically computes all the runtime dependencies
of a derivation, and it's possible thanks to the hash of the store
paths.

Steps:

1.  Dump the derivation as NAR, a serialization of the derivation
    output. Works fine whether it's a single file or a directory.

2.  For each build dependency .drv and its relative out path, search the
    contents of the NAR for this out path.

3.  If found, then it's a runtime dependency.

You get really all the runtime dependencies, and that's why Nix
deployments are so easy.

Ok glibc and gcc. Well, gcc really should not be a runtime dependency!

Oh Nix added gcc because its out path is mentioned in the "hello"
binary. Why is that? That's the [ld
rpath](http://en.wikipedia.org/wiki/Rpath). It's the list of directories
where libraries can be found at runtime. In other distributions, this is
usually not abused. But in Nix, we have to refer to particular versions
of libraries, thus the rpath has an important role.

The build process adds that gcc lib path thinking it may be useful at
runtime, but really it's not. How do we get rid of it? Nix authors have
written another magical tool called
[patchelf](https://nixos.org/patchelf.html), which is able to reduce the
rpath to the paths that are really used by the binary.

Even after reducing the rpath, the hello binary would still depend upon
gcc because of some debugging information. This unnecesarily increases
the size of our runtime dependencies. We'll explore how `strip
      ` can help us with that in the next section.

## Another phase in the builder

We will add a new phase to our autotools builder. The builder has these
phases already:

1.  First the environment is set up

2.  Unpack phase: we unpack the sources in the current directory
    (remember, Nix changes dir to a temporary directory first)

3.  Change source root to the directory that has been unpacked

4.  Configure phase: `./configure`

5.  Build phase: `make`

6.  Install phase: `make install`

We add a new phase after the installation phase, which we call **fixup**
phase. At the end of the `builder.sh` follows:

That is, for each file we run `patchelf --shrink-rpath` and `strip`.
Note that we used two new commands here, `find` and `patchelf`.
**Exercise:** These two deserve a place in `baseInputs` of
`autotools.nix` as `findutils` and `patchelf`.

Rebuild `hello.nix` and...:

...only glibc is the runtime dependency. Exactly what we wanted.

The package is self-contained, copy its closure on another machine and
you will be able to run it. Remember, only a very few components under
the `/nix/store` are required to [run
nix](#install-on-your-running-system). The hello binary will use that
exact version of glibc library and interpreter, not the system one:

Of course, the executable runs fine as long as everything is under the
`/nix/store` path.

## Conclusion

Short post compared to previous ones as I'm still on vacation, but I
hope you enjoyed it. Nix provides tools with cool features. In
particular, Nix is able to compute all runtime dependencies
automatically for us. This is not limited to only shared libraries, but
also referenced executables, scripts, Python libraries etc..

This makes packages self-contained, ensuring (apart data and
configuration) that copying the runtime closure on another machine is
sufficient to run the program. That's why Nix has [one-click
install](https://nixos.org/nix/manual/#ch-relnotes-0.8), or [reliable
deployment in the
cloud](http://nixos.org/nixops/manual/#chap-introduction). All with one
tool.

## Next pill

...we will introduce nix-shell. With nix-build we always build
derivations from scratch: the source gets unpacked, configured, built
and installed. But this may take a long time, think of WebKit. What if
we want to apply some small changes and compile incrementally instead,
yet keeping a self-contained environment similar to nix-build?
