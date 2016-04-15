(* Mathematica Package  *)
(* Created by IntelliJ IDEA http://wlplugin.halirutan.de/ *)

(* :Title: MaTeX *)
(* :Author: Szabolcs Horvát <szhorvat@gmail.com> *)
(* :Context: MaTeX` *)
(* :Version: 1.3.0 *)
(* :Date: 2015-03-04 *)

(* :Mathematica Version: 10 *)
(* :Copyright: (c) 2016 Szabolcs Horvát *)

(* Abort for old, unsupported versions of Mathematica *)
If[$VersionNumber < 10,
  Print["MaTeX requires Mathematica 10 or later."];
  Abort[]
]

If[$OperatingSystem === "Windows" && $VersionNumber == 10.0 && $SystemWordLength == 32,
  Print[
    "WARNING: MaTeX may not work with 32-bit versions of Mathematica 10.0 on Windows. " <>
    "If you encounter problems, consider using a 64-bit version or upgrading to a later Mathematica version."
  ]
]

BeginPackage["MaTeX`"]

MaTeX::usage = "\
MaTeX[\"texcode\"] compiles texcode using LaTeX and returns the result as Mathematica graphics.  texcode must be valid inline math-mode LaTeX code.
MaTeX[expression] converts expression to LaTeX using TeXForm, then compiles it and returns the result.";

BlackFrame::usage = "BlackFrame is a setting for FrameStyle or AxesStyle that produces the default look in black instead of gray.";

ConfigureMaTeX::usage = "\
ConfigureMaTeX[\"key1\" \[Rule] \"value1\", \"key2\" \[Rule] \"value2\", \[Ellipsis]] sets configuration options for MaTeX and stores them permanently.
ConfigureMaTeX[] returns the current configuration.";

ClearMaTeXCache::usage = "ClearMaTeXCache[] clears MaTeX's cache."

`Developer`$Version = "1.3.0 (April 16, 2016)";

Begin["`Private`"] (* Begin Private Context *)


(* workaround for Mathematica bug on Windows where RunProcess fails when run in directories with special chars in name *)
If[$OperatingSystem === "Windows",
  runProcess[args___] :=
      Module[{res},
        SetDirectory["\\"];
        res = RunProcess[args];
        ResetDirectory[];
        res
      ]
  ,
  runProcess = RunProcess
];


(* Load and check persistent configuration *)

$applicationDataDirectory = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MaTeX"}];
If[Not@DirectoryQ[$applicationDataDirectory], CreateDirectory[$applicationDataDirectory]]

$configFile = FileNameJoin[{$applicationDataDirectory, "config.m"}];

(* The following are best guess configurations for first-time setup *)

$defaultConfigBase = <| "pdfLaTeX" -> None, "Ghostscript" -> None, "CacheSize" -> 100 |>;

$defaultConfigOSX := <|
    "Ghostscript" -> Quiet@Check[If[FileExistsQ["/usr/local/bin/gs"], "/usr/local/bin/gs", None], None],
    "pdfLaTeX" -> Quiet@Check[If[FileExistsQ["/Library/TeX/texbin/pdflatex"], "/Library/TeX/texbin/pdflatex", None], None]
|>;

$defaultConfigLinux := <|
    "Ghostscript" -> Quiet@Check[First@ReadList["!which gs", String, 1], None],
    "pdfLaTeX" -> Quiet@Check[First@ReadList["!which pdflatex", String, 1], None]
|>;

winFindGS[] :=
    Quiet@Check[Module[{base, keys, vals, key, dll, exe},
      base = "HKEY_LOCAL_MACHINE\\SOFTWARE\\GPL Ghostscript";
      keys = Developer`EnumerateRegistrySubkeys[base];
      If[keys === $Failed,
        Return[None]
      ];
      key = Last@Sort[keys];
      vals = Developer`ReadRegistryKeyValues[base <> "\\" <> key];
      dll = Lookup[vals, "GS_DLL", $Failed];
      If[dll === $Failed,
        Return[None]
      ];
      If[Not@FileExistsQ[dll],
        Return[None]
      ];
      Switch[FileNameTake[dll],
        "gsdll64.dll", exe = "gswin64c.exe",
        "gsdll32.dll", exe = "gswin32c.exe",
        _, Return[None]
      ];
      AbsoluteFileName@FileNameJoin[{DirectoryName[dll], exe}]
    ], None]

winFindPL[] := Quiet@Check[AbsoluteFileName@First@ReadList["!where pdflatex.exe", String, 1], None]

$defaultConfigWindows := <|
    "Ghostscript" -> winFindGS[],
    "pdfLaTeX" -> winFindPL[]
|>

$defaultConfig :=
    Switch[$OperatingSystem,
      "MacOSX", Join[$defaultConfigBase, $defaultConfigOSX],
      "Unix", Join[$defaultConfigBase, $defaultConfigLinux],
      "Windows", Join[$defaultConfigBase, $defaultConfigWindows],
      _, $defaultConfigBase
    ]

(* Load configuration, if it exists *)
If[FileExistsQ[$configFile], $config = Import[$configFile, "Package"], $config = <||>];
If[Not@AssociationQ[$config],
  Print["The MaTeX configuration was corrupted so it had to be re-set. If you can reproduce this problem, please go to https://github.com/szhorvat/MaTeX and create a bug report."];
  $config = <||>
];

If[Not@SubsetQ[Keys[$config], Keys[$defaultConfigBase]],
  $config = Join[$defaultConfig, $config]
];
Export[$configFile, $config, "Package"];

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
      gsver = StringTrim@runProcess[{gs, "--version"}, "StandardOutput"];
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


(* XeTeX won't work on OS X and possibly other systems unless texbin is in the system path.
   This function appends that directory to the PATH environment variable if not already present. *)
fixSystemPath[] :=
    Module[{texpath, pathList, pathSeparator},
      If[Not[$configOK], Return[$Failed]];
      texpath = AbsoluteFileName@DirectoryName@ExpandFileName[$config["pdfLaTeX"]];
      pathSeparator = If[$OperatingSystem === "Windows", ";", ":"];
      pathList = Quiet[
        AbsoluteFileName /@ StringSplit[Environment["PATH"], pathSeparator],
        {AbsoluteFileName::nffil, AbsoluteFileName::fdnfnd, General::fstr}
      ];
      If[Not@MemberQ[pathList, texpath],
        SetEnvironment["PATH" -> Environment["PATH"] <> pathSeparator <> texpath]
      ];
      Environment["PATH"]
    ]


checkConfig[] (* check configuration and set $configOK *)
debugPrint["System path: ", fixSystemPath[]]


debugPrint["Configuration: ", $config]
debugPrint["Confguration is valid: ", $configOK]


ConfigureMaTeX::badkey = "Unknown configuration key: ``";
SyntaxInformation[ConfigureMaTeX] = {"ArgumentsPattern" -> {OptionsPattern[]}, "OptionNames" -> {"pdfLaTeX", "Ghostscript", "CacheSize"}};

ConfigureMaTeX[rules___Rule] :=
    (Scan[
      If[KeyExistsQ[$config, First[#]], AppendTo[$config, #], Message[ConfigureMaTeX::badkey, First[#]]]&,
      {rules}
    ];
    checkConfig[];
    fixSystemPath[];
    Export[$configFile, $config, "Package"];
    Normal[$config]
    )


ranid[] := StringJoin@RandomChoice[CharacterRange["a", "z"], 16]


(* Create temporary directory *)
dirpath = FileNameJoin[{$TemporaryDirectory, StringJoin["MaTeX_", ranid[]]}]
debugPrint["Creating temporary directory: ", dirpath]
CreateDirectory[dirpath]

(* Thank you to David Carlisle and Tom Hejda for help with the LaTeX code. *)
template = StringTemplate["\
\\documentclass[12pt,border=1pt]{standalone}
\\usepackage[utf8]{inputenc}
`preamble`
\\begin{document}
\\fontsize{`fontsize`pt}{`skipsize`pt}\\selectfont
\\newbox\\MaTeXbox
\\setbox\\MaTeXbox\\hbox{`strut`\(`display` `tex`\)}%
\\typeout{MATEXDEPTH:\\the\\dp\\MaTeXbox}%
\\typeout{MATEXHEIGHT:\\the\\ht\\MaTeXbox}%
\\typeout{MATEXWIDTH:\\the\\wd\\MaTeXbox}%
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

(* This function is used to try to detect errors based on the log file.
   It is necessary because on Windows RunProcess doesn't capture the correct exit code. *)
texErrorQ[log_String] := Count[StringSplit[log, "\n"], line_ /; StringMatchQ[line, "! *"]] > 0

getDimensions[log_String] := Interpreter["Number"]@First@StringCases[log, RegularExpression["MATEX"<>#<>":(.+?)pt"] -> "$1"]& /@ {"WIDTH", "HEIGHT", "DEPTH"}

extractOption[g_, opt_] := opt /. Options[g, opt]


cache = <||>

SetAttributes[store, HoldFirst]
store[memoStore_, key_, value_] :=
    (AppendTo[memoStore, key -> value];
    If[Length[memoStore] > $config["CacheSize"], memoStore = Rest[memoStore]];
    value
    )


SyntaxInformation[ClearMaTeXCache] = {"ArgumentsPattern" -> {}};
ClearMaTeXCache[] := (cache = <||>;)


Options[MaTeX] = {
  "Preamble" -> {"\\usepackage{lmodern,exscale}", "\\usepackage{amsmath,amssymb}"},
  "DisplayStyle" -> True,
  ContentPadding -> True,
  LineSpacing -> {1.2, 0},
  FontSize -> 12,
  Magnification -> 1,
  "LogFileFunction" -> None,
  "TeXFileFunction" -> None
};
SyntaxInformation[MaTeX] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

MaTeX::gserr = "Error while running Ghostscript.";
MaTeX::texerr = "Error while running LaTeX:\n``";
MaTeX::importerr = "Failed to import PDF.  This is unexpected.  Please go to https://github.com/szhorvat/MaTeX and create a bug report.";
MaTeX::invopt = "Invalid option value: ``.";

$psfactor = 72/72.27; (* conversion factor from TeX points to PostScript points *)

iMaTeX[tex_String, preamble_, display_, fontsize_, strut_, ls : {lsmult_, lsadd_}, logFileFun_, texFileFun_] :=
    Module[{key, cleanup, name, content,
            texfile, pdffile, pdfgsfile, logfile, auxfile,
            return, result,
            width, height, depth},

      key = {tex, Sort[preamble], display, fontsize, strut, ls};
      If[KeyExistsQ[cache, key],
        Return[cache[key]]
      ];

      cleanup[] := If[fileQ[#], DeleteFile[#]]& /@ {texfile, pdffile, pdfgsfile, logfile, auxfile};
      name = ranid[];

      (* Note: StringTemplate automatically numericizes expressions like Sqrt[2]. *)
      content = <|
          "preamble" -> StringJoin@Riffle[preamble, "\n"],
          "tex" -> tex,
          "display" -> If[display, "\\displaystyle", ""],
          "strut" -> If[strut, "\\strut", ""],
          "fontsize" -> fontsize,
          "skipsize" -> lsmult fontsize + lsadd
          |>;
      texfile = Export[FileNameJoin[{dirpath, name <> ".tex"}], template[content], "Text", CharacterEncoding -> "UTF-8"];
      If[texFileFun =!= None, With[{str = Import[texfile, "String"]}, texFileFun[str]]];

      pdffile = FileNameJoin[{dirpath, name <> ".pdf"}];
      pdfgsfile = FileNameJoin[{dirpath, name <> "-gs.pdf"}];
      logfile = FileNameJoin[{dirpath, name <> ".log"}];
      auxfile = FileNameJoin[{dirpath, name <> ".aux"}];

      return = runProcess[{$config["pdfLaTeX"], "-halt-on-error", "-interaction=nonstopmode", texfile}, ProcessDirectory -> dirpath];
      If[logFileFun =!= None, With[{str = Import[logfile, "String"]}, logFileFun[str]]];

      If[return["ExitCode"] != 0 || texErrorQ[return["StandardOutput"]] (* workaround for Windows version *),
        Message[MaTeX::texerr, parseTeXError[return["StandardOutput"]]];
        cleanup[];
        Return[$Failed]
      ];

      {width, height, depth} = getDimensions[return["StandardOutput"]];
      (* +2 is for the 1 pt border on each side *)
      width  += 2;
      height += depth+2;
      {width, height, depth} *= $psfactor; (* correct for PostScript point *)

      return = runProcess[{$config["Ghostscript"], "-o", pdfgsfile, "-dNoOutputFonts", "-sDEVICE=pdfwrite", pdffile}, ProcessDirectory -> dirpath];
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
      result = Show[result, ImageSize -> {width, height}, BaselinePosition -> Scaled[(depth+$psfactor)/height]]; (* +$psfactor is for 1 pt border *)

      store[cache, key, result]
    ]

MaTeX[tex_String, opt:OptionsPattern[]] :=
    Module[{preamble, mag, result},
      If[! $configOK, checkConfig[]; Return[$Failed]];
      preamble = OptionValue["Preamble"];
      If[Not@VectorQ[preamble, StringQ],
        Message[MaTeX::invopt, "Preamble" -> preamble];
        Return[$Failed]
      ];
      If[Not@BooleanQ@OptionValue["DisplayStyle"],
        Message[MaTeX::invopt, "DisplayStyle" -> OptionValue["DisplayStyle"]];
        Return[$Failed]
      ];
      If[Not@BooleanQ@OptionValue[ContentPadding],
        Message[MaTeX::invopt, ContentPadding -> OptionValue[ContentPadding]];
        Return[$Failed]
      ];
      If[Not[NumericQ@OptionValue[FontSize] && TrueQ@Positive@OptionValue[FontSize]],
        Message[MaTeX::invopt, FontSize -> OptionValue[FontSize]];
        Return[$Failed]
      ];
      If[Not[MatchQ[OptionValue[LineSpacing], {mult_, add_} /; NumericQ[mult] && TrueQ@NonNegative[mult] && NumericQ[add]]],
        Message[MaTeX::invopt, LineSpacing -> OptionValue[LineSpacing]];
        Return[$Failed]
      ];
      mag = OptionValue[Magnification];
      If[Not[NumericQ[mag] && TrueQ@Positive[mag]],
        Message[MaTeX::invopt, Magnification -> mag];
        Return[$Failed]
      ];
      result =
          iMaTeX[tex, preamble,
            OptionValue["DisplayStyle"], OptionValue[FontSize], OptionValue[ContentPadding], OptionValue[LineSpacing],
            OptionValue["LogFileFunction"], OptionValue["TeXFileFunction"]
          ];
      If[result === $Failed || TrueQ[mag == 1], result, Show[result, ImageSize -> N[mag] extractOption[result, ImageSize]]]
    ]

MaTeX[tex_StringForm, opt:OptionsPattern[]] := MaTeX[ToString[tex], opt]

MaTeX[tex_, opt:OptionsPattern[]] := MaTeX[ToString@TeXForm[tex], opt]


BlackFrame = Directive[AbsoluteThickness[0.5], Black]

End[] (* End Private Context *)

EndPackage[]
