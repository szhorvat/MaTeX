(* Mathematica Package  *)
(* Created by IntelliJ IDEA http://wlplugin.halirutan.de/ *)

(* :Title: MaTeX *)
(* :Author: Szabolcs Horvát <szhorvat@gmail.com> *)
(* :Context: MaTeX` *)
(* :Version: 0.2dev *)
(* :Date: 2015-03-04 *)

(* :Mathematica Version: 10 *)
(* :Copyright: (c) 2015 Szabolcs Horvát *)


BeginPackage["MaTeX`"]

MaTeX::usage = "MaTeX[texcode] will compile texcode using LaTeX and import the result into Mathematica as graphics.  texcode must be a string containing valid math-mode LaTeX code."
BlackFrame::usage = "Use FrameStyle -> BlackFrame to get the default frame style in black instead of gray."
ConfigureMaTeX::usage = "ConfigureMaTeX[\"key1\" -> \"value1\", \"key2\" -> \"value2\", ...] will set configuration options for MaTeX."
ClearMaTeXCache::usage = "ClearMaTeXCache[] will clear MaTeX's cache."

Begin["`Private`"] (* Begin Private Context *)

(* Abort for old, unsupported versions of Mathematica *)
If[$VersionNumber < 10,
  Print["MaTeX requires Mathematica 10 or later."];
  Abort[]
]


(* Load and check persistent configuration *)

$applicationDataDirectory = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MaTeX"}]
If[Not@DirectoryQ[$applicationDataDirectory], CreateDirectory[$applicationDataDirectory]]

$configFile = FileNameJoin[{$applicationDataDirectory, "config.m"}]

If[FileExistsQ[$configFile], $config = Import[$configFile, "Package"], $config = <||>]

$config = Join[<| "pdfLaTeX" -> None, "Ghostscript" -> None, "CacheSize" -> 50 |>, $config]
Export[$configFile, $config, "Package"]

(* True if file exists and is not a directory *)
fileQ[file_] := FileExistsQ[file] && Not@DirectoryQ[file]

checkConfig[] :=
  Module[{pdflatex, gs, pdflatexOK, gsOK, cacheSizeOK, gsver},
    pdflatex = $config["pdfLaTeX"];
    If[StringQ[pdflatex],
      If[fileQ[pdflatex],
        pdflatexOK = True,
        Print["pdfLaTeX is not found at " <> pdflatex];
        pdflatexOK = False
      ],
      Print["The path to pdfLaTeX is not configured."];
      pdflatexOK = False
    ];

    If[!pdflatexOK, Print["Please configure pdfLaTeX using ConfigureMaTeX[\"pdfLaTeX\" -> \"path to pdflatex executable...\"]"]];

    gs = $config["Ghostscript"];
    If[StringQ[gs],
      If[fileQ[gs],
        gsOK = True,
        Print["Ghostscript is not found at " <> gs];
        gsOK = False
      ],
      Print["The path to Ghostscipt is not configured."];
      gsOK= False
    ];

    If[gsOK,
      gsver = StringTrim@RunProcess[{gs, "--version"}, "StandardOutput"];
      If[Not@OrderedQ[{{9,15}, FromDigits /@ StringSplit[gsver, "."]}],
        Print["Ghostscript version " <> gsver <> " found.  MaTeX requires Ghostscript 9.15 or later."];
        gsOK = False;
      ]
    ];

    If[!gsOK, Print["Please configure Ghostscript using ConfigureMaTeX[\"Ghostscript\" -> \"path to gs executable...\"]"]];

    If[Not@TrueQ@NonNegative[$config["CacheSize"]],
      Print["CacheSize must be a nonnegative number.  Please update the configuration using ConfigureMaTeX[\"CacheSize\" -> ...]."];
      cacheSizeOK = False,
      cacheSizeOK = True
    ];

    $configOK = pdflatexOK && gsOK && cacheSizeOK;
  ]

checkConfig[] (* check configuration and set $configOK *)

debugPrint["Configuration: ", $config]
debugPrint["Confguration is valid: ", $configOK]

ConfigureMaTeX::badkey = "Unknown configuration key: ``"

ConfigureMaTeX[rules___Rule] :=
    (Scan[
      If[KeyExistsQ[$config, First[#]], AppendTo[$config, #], Message[ConfigureMaTeX::badkey, First[#]]]&,
      {rules}
    ];
    checkConfig[];
    Export[$configFile, $config, "Package"];
    Normal[$config]
    )


ranid[] := StringJoin@RandomChoice[CharacterRange["a", "z"], 16]


(* Create temporary directory *)
dirpath = FileNameJoin[{$TemporaryDirectory, StringJoin["MaTeX_", ranid[]]}]
debugPrint["Creating temporary directory: ", dirpath]
CreateDirectory[dirpath]

$scalingFactor = 5;

template = StringTemplate["\
\\mag=" <> IntegerString@Round[1000 $scalingFactor] <> "
\\documentclass[12pt,border=0.5pt]{standalone}
\\usepackage[utf8]{inputenc}
`preamble`
\\begin{document}
\\newbox\\MaTeXbox
\\setbox\\MaTeXbox\\hbox{\\strut$`display` `tex`$}%
\\typeout{MATEXDEPTH:\\the\\dp\\MaTeXbox}%
\\unhbox\\MaTeXbox
\\end{document}
"];

parseTeXError[err_String] :=
    StringJoin@Riffle[
      StringDrop[#, 2] & /@ Select[
        StringSplit[err, "\n"],
        StringMatchQ[#, "! *"] &
      ],
      "\n"
    ]

getDepth[log_String] := Interpreter["Number"]@First@StringCases[log, RegularExpression["MATEXDEPTH:(.+?)pt"] -> "$1"]

extractOption[g_, opt_] := opt /. Options[g, opt]


cache = <||>

SetAttributes[store, HoldFirst]
store[memoStore_, key_, value_] :=
    (AppendTo[memoStore, key -> value];
    If[Length[memoStore] > $config["CacheSize"], memoStore = Rest[memoStore]];
    value
    )

ClearMaTeXCache[] := (cache = <||>;)

Options[MaTeX] = {
  "Preamble" -> {"\\usepackage{amsmath,amssymb}"},
  "DisplayStyle" -> True,
  Magnification -> 1
}

MaTeX::gserr = "Error while running Ghostscript."
MaTeX::texerr = "Error while running LaTeX:\n``"
MaTeX::importerr = "Failed to import PDF.  This is unexpected.  Please go to https://github.com/szhorvat/MaTeX for instructions on how to report this problem."
MaTeX::invopt = "Invalid option value: ``"

iMaTeX[tex_String, preamble_, display_] :=
    Module[{key, cleanup, name, content, texfile, pdffile, pdfgsfile, logfile, auxfile, return, result, depth, size},

      key = {tex, Sort[preamble], display};
      If[KeyExistsQ[cache, key],
        Return[cache[key]]
      ];

      cleanup[] := If[fileQ[#], DeleteFile[#]]& /@ {texfile, pdffile, pdfgsfile, logfile, auxfile};
      name = ranid[];

      content = <|
          "preamble" -> StringJoin@Riffle[preamble, "\n"],
          "tex" -> tex,
          "display" -> If[display, "\\displaystyle", ""]
          |>;
      texfile = Export[FileNameJoin[{dirpath, name <> ".tex"}], template[content], "Text", CharacterEncoding -> "UTF-8"];
      pdffile = FileNameJoin[{dirpath, name <> ".pdf"}];
      pdfgsfile = FileNameJoin[{dirpath, name <> "-gs.pdf"}];
      logfile = FileNameJoin[{dirpath, name <> ".log"}];
      auxfile = FileNameJoin[{dirpath, name <> ".aux"}];

      return = RunProcess[{$config["pdfLaTeX"], "-halt-on-error", "-interaction=nonstopmode", texfile}, ProcessDirectory -> dirpath];
      If[return["ExitCode"] != 0,
        Message[MaTeX::texerr, parseTeXError[return["StandardOutput"]]];
        cleanup[];
        Return[$Failed]
      ];

      depth = 72.27/72*(getDepth[return["StandardOutput"]] + 0.5); (* location of the baseline relative to the bottom, in points *)

      return = RunProcess[{$config["Ghostscript"], "-o", pdfgsfile, "-dNoOutputFonts", "-sDEVICE=pdfwrite", pdffile}, ProcessDirectory -> dirpath];
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

      result = First[result];
      size = 1./$scalingFactor extractOption[result, ImageSize];
      result = Show[result, ImageSize -> size, BaselinePosition -> Scaled[depth / Last[size]]];

      store[cache, key, result]
    ]

MaTeX[tex_String, opt:OptionsPattern[]] :=
    Module[{preamble, mag, result},
      If[! $configOK, checkConfig[]; Return[$Failed]];
      preamble = OptionValue["Preamble"];
      If[Not@VectorQ[preamble, StringQ],
        Message[MaTeX::invopt, "Preamble" -> preamble];
        Return[$Failed];
      ];
      If[Not@MatchQ[OptionValue["DisplayStyle"], True|False],
        Message[MaTeX::invopt, "DisplayStyle" -> OptionValue["DisplayStyle"]];
        Return[$Failed];
      ];
      mag = OptionValue[Magnification];
      result = iMaTeX[tex, preamble, OptionValue["DisplayStyle"]];
      If[result === $Failed || TrueQ[mag == 1], result, Style[result, Magnification -> mag]]
    ]

MaTeX[tex_, opt:OptionsPattern[]] := MaTeX[ToString@TeXForm[tex], opt]


BlackFrame = Directive[AbsoluteThickness[0.5], Black]

End[] (* End Private Context *)

EndPackage[]