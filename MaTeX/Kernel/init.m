(* Kernel/init.m *)

(* Reminder: Avoid mentioning any non-System` symbols in this file,
   otherwise they will be created in Global` when the package is loaded. *)

(* Abort immediately for old, unsupported versions of Mathematica *)
If[$VersionNumber < 10,
  Print["MaTeX requires Mathematica 10.0 or later."];
  Abort[]
]

If[$OperatingSystem === "Windows" && $VersionNumber == 10.0 && $SystemWordLength == 32,
  Print[
    "WARNING: MaTeX may not work with 32-bit versions of Mathematica 10.0 on Windows. " <>
    "If you encounter problems, consider using a 64-bit version or upgrading to a later Mathematica version."
  ]
]

(* Unprotect package symbols in case MaTeX is double-loaded *)
Unprotect["MaTeX`*", "MaTeX`Developer`*", "MaTeX`Information`*"];

(* Load the package *)
Get["MaTeX`MaTeX`"]

(* Protect all package symbols *)
SetAttributes[
  Evaluate@Flatten[Names /@ {"MaTeX`*", "MaTeX`Developer`*", "MaTeX`Information`*"}],
  {Protected, ReadProtected}
]
