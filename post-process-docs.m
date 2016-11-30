(* Mathematica Source File  *)
(* Created by Mathematica Plugin for IntelliJ IDEA *)
(* :Author: szhorvat *)
(* :Date: 2016-11-28 *)

(* Run this script optionally for minor improvements to the built documentation.
   Requires PackageTools, https://github.com/szhorvat/PackageTools
*)

AddPath["PackageTools"]
Needs["PackageTools`"]

SetDirectory@DirectoryName[$InputFileName]

$appName = "MaTeX";

$docDir = FileNameJoin[{"build", $appName, "Documentation"}];

If[Not@DirectoryQ[$docDir],
  Print["Documentation directory not found.  Aborting."];
  Abort[]
]

code =
    With[{$docDir = $docDir, $appName = $appName},
      MCode[
        files = FileNames["*.nb", $docDir, Infinity];
        process[file_] :=
            Module[{nb},
              Print[file];
              nb = Import[file];
              nb = NBSetOptions[Saveable -> False]@NBDeleteCellTags["HideInput"]@NBRemoveURL@NBHideInput[nb];
              Export[file, nb];
            ];
        Scan[process, files]
      ]
    ];

(* Process in version 10.0 to avoid InsufficientVersionWarning *)
MRun[code, "10.0"]
