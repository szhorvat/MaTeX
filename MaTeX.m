(* Mathematica Package  *)
(* Created by IntelliJ IDEA http://wlplugin.halirutan.de/ *)

(* :Title: MaTeX *)
(* :Context: MaTeX` *)
(* :Author: Szabolcs Horvát *)
(* :Date: 2015-03-04 *)

(* :Mathematica Version: 10 *)
(* :Copyright: (c) 2015 Szabolcs Horvát *)


BeginPackage["MaTeX`"]

MaTeX::usage = "MaTeX[texcode] will compile texcode using LaTeX and import the result into Mathematica as graphics.  texcode must be a string containing valid math-mode LaTeX code."
BlackFrame::usage = "Use FrameStyle -> BlackFrame to get the default frame style in black."

Begin["`Private`"] (* Begin Private Context *)

BlackFrame = Directive[AbsoluteThickness[0.5], Black];

pdflatex = "/usr/texbin/pdflatex";
gs = "/usr/local/bin/gs";

(* Verify external dependencies: *)

If[$VersionNumber < 10,
  Print["MaTeX requires Mathematica 10 or later."];
  Abort[]
]

If[Not@FileExistsQ[gs],
  Print["Ghostscript not found."]; Abort[]
]

gsver = StringTrim@RunProcess[{gs, "--version"}, "StandardOutput"];

If[Not@OrderedQ[{{9,15}, FromDigits /@ StringSplit[gsver, "."]}],
  Print["Ghostscript version " <> gsver <> " found.  MaTeX requires Ghostscript 9.15 or later."];
  Abort[]
]

If[Not@FileExistsQ[pdflatex],
  Print["pdflatex not found."; Abort[]]
]

ranid[] := StringJoin@RandomChoice[CharacterRange["a", "z"], 16]

dirpath = FileNameJoin[{$TemporaryDirectory, StringJoin["MaTeX_", ranid[]]}]
CreateDirectory[dirpath]

template = StringTemplate@"\
\\documentclass[12pt]{standalone}
\\usepackage{amsmath}
\\begin{document}
\\strut$\\displaystyle ``$
\\end{document}
";

parseTeXError[err_String] := StringJoin@Riffle[
  StringDrop[#, 2] & /@ Select[
    StringSplit[err, "\n"],
    StringMatchQ[#, "! *"] &
  ],
  "\n"
]


cache = <||>;
$cacheSize = 50;

SetAttributes[store, HoldFirst]
store[memoStore_, key_, value_] :=
    (AppendTo[memoStore, key -> value];
    If[Length[memoStore] > $cacheSize, memoStore = Rest[memoStore]];
    value
    )

MaTeX::gserr = "Error while running Ghostscript.";
MaTeX::texerr = "Error while running LaTeX:\n``";
MaTeX::importerr = "Failed to import PDF.  This is unexpected.  Please go to https://github.com/szhorvat/MaTeX for instructions on how to report this problem.";

iMaTeX[tex_String] :=
    Module[{cleanup, name, texfile, pdffile, pdfgsfile, logfile, auxfile, return, result},

      If[KeyExistsQ[cache, tex],
        Return[cache[tex]]
      ];

      cleanup[] := If[FileExistsQ[#], DeleteFile[#]]& /@ {texfile, pdffile, pdfgsfile, logfile, auxfile};
      name = ranid[];

      texfile = Export[FileNameJoin[{dirpath, name <> ".tex"}], template[tex], "String"];
      pdffile = FileNameJoin[{dirpath, name <> ".pdf"}];
      pdfgsfile = FileNameJoin[{dirpath, name <> "-gs.pdf"}];
      logfile = FileNameJoin[{dirpath, name <> ".log"}];
      auxfile = FileNameJoin[{dirpath, name <> ".aux"}];

      return = RunProcess[{pdflatex, "-halt-on-error", "-interaction=nonstopmode", "-output-directory=" <> dirpath, texfile}, All, ProcessDirectory -> dirpath];
      If[return["ExitCode"] != 0,
        Message[MaTeX::texerr, parseTeXError[return["StandardOutput"]]];
        cleanup[];
        Return[$Failed]
      ];

      return = RunProcess[{gs, "-o", pdfgsfile, "-dNoOutputFonts", "-sDEVICE=pdfwrite", pdffile}, All, ProcessDirectory -> dirpath];
      If[return["ExitCode"] != 0,
        Message[MaTeX::gserr];
        cleanup[];
        Return[$Failed]
      ];

      result = Import[pdfgsfile, "PDF"];
      cleanup[];
      If[result === $Failed,
        Message[MaTeX::importerr];
        Return[$Failed]
      ];

      store[cache, tex, First[result]]
    ]

MaTeX[tex_String] := iMaTeX[tex]
MaTeX[tex_] := iMaTeX@ToString@TeXForm[tex]


End[] (* End Private Context *)

EndPackage[]