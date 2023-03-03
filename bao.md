---
title: Bao
author: Rüdiger Klaehn
theme: Copenhagen
date: March 2, 2023
lang: en
  
---

#

![](img/blake3.svg)

# What is blake3

- Cryptographic hash function
- Evolution of the Blake2 family
- One hash function, not a family
  - tagline **one function, fast everywhere**
- [XOF], [KDF], [PRF] and [MAC]
- Parallelism ([SIMD] and multithreading)

# Fast

![](img/speed.svg)

# SIMD

![](img/SIMD.svg)

# Fewer rounds

[![](img/toomuchcrypto.png)](refs/too_much_crypto.pdf)

# How does it work

# Chunks

![](img/blake-tree-24.svg)

- Compute hash of chunk of up to 1024 bytes
- Use of SIMD instructions

# Larger files

![](img/blake-tree-25.svg)

- binary tree to combine chunk hashes
- lopsided
- root gets special flag
- multithreading
- in blake3, binary tree is ephemeral

#
![](img/blake-tree-0.svg)

#
![](img/blake-tree-1.svg)

#
![](img/blake-tree-2.svg)

#
![](img/blake-tree-3.svg)

#
![](img/blake-tree-4.svg)

#
![](img/blake-tree-5.svg)

#
![](img/blake-tree-6.svg)

#
![](img/blake-tree-7.svg)

#

<img src="img/bao.svg"  width="500">

- Persist branch hashes of binary tree
- Verified streaming of entire data
- Verified streaming of ranges
- Outboard and inline mode

# Verified streaming

- Verify while receiving data
- Wrong data will be discovered after 1 chunk

# Data encoding

- as you write it - post order
- as you need it when encoding - pre order
- finish / flip from post to pre order

#
![](img/blake-tree-8.svg)

#
![](img/blake-tree-9.svg)

#
![](img/blake-tree-10.svg)

#
![](img/blake-tree-11.svg)

#
![](img/blake-tree-12.svg)

#
![](img/blake-tree-13.svg)

#
![](img/blake-tree-14.svg)

#
![](img/blake-tree-15.svg)

# Inline

- 8 byte header, total size, le
- 64 byte tree nodes, 2 hashes
- 1024 byte data blocks, come in pairs
- last block can be <1024 bytes

# Outboard

- 8 byte header, total size, le
- 64 byte tree nodes, 2 hashes
- Original file can remain unchanged

#
![](img/blake-tree-16.svg)

# Slice encoding

- encode just a slice of a large file
- think HTML range requests
- verified data *and* position

#
![](img/blake-tree-20.svg)

#
![](img/blake-tree-21.svg)

# Chunk groups

#
![](img/blake-tree-17.svg)

#
![](img/blake-tree-18.svg)

#
![](img/blake-tree-19.svg)

# Size proofs

- You want to know total size

#
![](img/blake-tree-22.svg)

# Size proofs and chunk groups

#
![](img/blake-tree-23.svg)

# End

# Links

[Blake3 spec]: https://github.com/BLAKE3-team/BLAKE3-specs/blob/master/blake3.pdf
[XOF]: https://en.wikipedia.org/wiki/Category:Extendable-output_functions
[KDF]: https://en.wikipedia.org/wiki/Key_derivation_function
[PRF]: https://en.wikipedia.org/wiki/Pseudorandom_function_family
[MAC]: https://en.wikipedia.org/wiki/HMAC
[SIMD]: https://en.wikipedia.org/wiki/Single_instruction,_multiple_data
[Cryptographic hash function] https://en.wikipedia.org/wiki/Cryptographic_hash_function
[Too much crypto]: https://eprint.iacr.org/2019/1492.pdf

https://en.wikipedia.org/wiki/BLAKE_(hash_function)
https://github.com/BLAKE3-team/BLAKE3/
https://github.com/oconnor663/bao
