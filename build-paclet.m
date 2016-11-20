(* ::Package:: *)

$appName = "MaTeX";


printAbort[str_] := (Print["ABORTING: ", Style[str, Red, Bold]]; Quit[])


$dir = 
	Which[
		$InputFileName =!= "", DirectoryName[$InputFileName],
		$Notebooks, NotebookDirectory[],
		True, printAbort["Cannot determine script directory."]
	];


SetDirectory[$dir]


If[Not@DirectoryQ[$appName], printAbort["Application directory not found."]]


Check[
	PacletDirectoryAdd[$appName];
	Needs[$appName <> "`"],
	printAbort["Cannot add paclet directory and load package."]
]


If[AbsoluteFileName[$appName] =!= Lookup[PacletInformation[$appName], "Location"],
	printAbort["Wrong paclet loaded."]
]


date = DateString[{"Year", "Month", "Day"}];
time = DateString[{"Hour24", "Minute", "Second"}];


$buildDir = StringTemplate["``-``-``"][$appName, date, time]


If[DirectoryQ[$buildDir], printAbort["Build directory already exists."] ]


template = 
  StringTemplate[
    Import[FileNameJoin[{$appName, $appName <> ".m"}], "String"],
    Delimiters->"%%"
  ];


versionData = <|
	"version" -> Lookup[PacletInformation[$appName], "Version"],
	"date" -> DateString[{"MonthName"," ","Day",", ","Year"}]
|>


$appDir = FileNameJoin[{$buildDir, $appName}]


CreateDirectory[$buildDir]


CopyDirectory[$appName, $appDir]


DeleteDirectory[FileNameJoin[{$appDir, "Documentation"}], DeleteContents -> True]


CopyDirectory[
	FileNameJoin[{"build", $appName, "Documentation"}],
	FileNameJoin[{$appDir, "Documentation"}]
]


CopyFile["LICENSE.txt", FileNameJoin[{$appDir, "LICENSE.txt"}]]


Export[FileNameJoin[{$appDir, $appName<>".m"}], template[versionData], "String"]


DeleteFile /@ FileNames[".*", $appDir, Infinity]


PackPaclet[$appDir]


DeleteDirectory[$appDir, DeleteContents->True]


ResetDirectory[]
